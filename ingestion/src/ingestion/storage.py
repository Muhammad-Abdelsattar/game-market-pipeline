import boto3
import json
from botocore.exceptions import ClientError
from .config import config
from .logger import get_logger

logger = get_logger("Storage")

class S3Writer:
    def __init__(self):
        # If S3_ENDPOINT is set (e.g., localhost:9000), boto3 uses it.
        # If None, boto3 uses default AWS endpoints.
        self.s3 = boto3.client(
            's3',
            endpoint_url=config.S3_ENDPOINT,
            aws_access_key_id=config.AWS_ACCESS_KEY,
            aws_secret_access_key=config.AWS_SECRET_KEY
        )
        self.bucket = config.BUCKET_NAME

    def exists(self, path: str) -> bool:
        """Checks if a file exists in S3 to allow skipping."""
        try:
            self.s3.head_object(Bucket=self.bucket, Key=path)
            return True
        except ClientError:
            return False

    def save_json(self, data: dict, path: str):
        """
        Saves a dictionary as a JSON file to S3/MinIO.
        path example: 'raw/games/2023-11-18/page_1.json'
        """
        try:
            json_body = json.dumps(data)
            self.s3.put_object(
                Bucket=self.bucket,
                Key=path,
                Body=json_body,
                ContentType='application/json'
            )
            logger.info(f"Successfully uploaded: s3://{self.bucket}/{path}")
        except ClientError as e:
            logger.error(f"Failed to upload to S3: {e}")
            raise
