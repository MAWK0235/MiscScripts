import boto3
import os
import sys
from concurrent.futures import ThreadPoolExecutor

# CONFIGURATION
BUCKET_NAME = 'pentestworkdocs'
REGION = 'us-east-1' 
MAX_WORKERS = 15     

def upload_file(file_path, s3_client):
    if not os.path.isfile(file_path):
        print(f"[-] ERROR: {file_path} is not a valid file.")
        return

    file_name = os.path.basename(file_path)
    
    try:
        s3_client.upload_file(file_path, BUCKET_NAME, file_name)
        print(f"[+] SUCCESS: {file_name} -> s3://{BUCKET_NAME}/{file_name}")
    except Exception as e:
        print(f"[-] FAILURE: {file_name} | Error: {e}")

def main():
    if len(sys.argv) < 2:
        print("USAGE: python3 s3_uploader.py <file1> <file2> ...")
        sys.exit(1)

    try:
        s3 = boto3.client('s3', region_name=REGION)
    except Exception as e:
        print(f"[-] CRITICAL: Boto3 initialization failed: {e}")
        sys.exit(1)

    files_to_upload = sys.argv[1:]

    print(f"[*] TARGET BUCKET: {BUCKET_NAME}")
    print(f"[*] REGION: {REGION}")
    print(f"[*] UPLOADING: {len(files_to_upload)} files via {MAX_WORKERS} threads.")

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        for file_path in files_to_upload:
            executor.submit(upload_file, file_path, s3)

    print("[*] OPERATION COMPLETE.")

if __name__ == "__main__":
    main()
