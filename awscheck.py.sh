import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError, ClientError
import configparser
import os

# Path to AWS credentials file
credentials_file = os.path.expanduser("~/.aws/credentials")

def validate_credentials(file_path):
    config = configparser.ConfigParser()
    config.read(file_path)

    results = {}
    for profile in config.sections():
        try:
            # Extract credentials
            aws_access_key = config[profile].get("aws_access_key_id")
            aws_secret_key = config[profile].get("aws_secret_access_key")

            if not aws_access_key or not aws_secret_key:
                raise PartialCredentialsError(provider="profile", cred_var="aws_access_key_id/aws_secret_access_key")

            # Create an STS client with the credentials
            session = boto3.Session(aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key)
            sts_client = session.client("sts")
            
            # Call GetCallerIdentity to verify credentials
            identity = sts_client.get_caller_identity()
            results[profile] = f"Valid credentials: Account {identity['Account']}, User {identity['Arn']}"
        except PartialCredentialsError:
            results[profile] = "Invalid or incomplete credentials"
        except NoCredentialsError:
            results[profile] = "Credentials not found"
        except ClientError as e:
            error_code = e.response['Error']['Code']
            results[profile] = f"Failed: {error_code} - {e.response['Error']['Message']}"
    
    return results

if __name__ == "__main__":
    results = validate_credentials(credentials_file)
    for profile, status in results.items():
        print(f"[{profile}] {status}")
