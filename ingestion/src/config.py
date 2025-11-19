import os


class Config:
    RAWG_API_KEY = os.getenv("RAWG_API_KEY")
    RAWG_BASE_URL = "https://api.rawg.io/api"

    # Storage Config
    AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY_ID") or os.getenv("MINIO_ROOT_USER")
    AWS_SECRET_KEY = os.getenv("AWS_SECRET_ACCESS_KEY") or os.getenv(
        "MINIO_ROOT_PASSWORD"
    )
    S3_ENDPOINT = os.getenv("MINIO_ENDPOINT")  # None on AWS, URL on Local
    BUCKET_NAME = os.getenv("DATA_LAKE_BUCKET", "rawg-lake")

    # Defaults
    PAGE_SIZE = 40  # Max allowed by RAWG is 40

    def validate(self):
        if not self.RAWG_API_KEY:
            raise ValueError("Missing RAWG_API_KEY in environment variables.")
        if not self.AWS_ACCESS_KEY or not self.AWS_SECRET_KEY:
            raise ValueError("Missing Storage Credentials (AWS or MINIO).")
        return True


config = Config()
