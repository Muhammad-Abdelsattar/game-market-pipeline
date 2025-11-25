import os


class Config:
    RAWG_API_KEY = os.getenv("RAWG_API_KEY")
    RAWG_BASE_URL = "https://api.rawg.io/api"

    # Storage Config
    AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY_ID") or os.getenv("MINIO_ROOT_USER")
    AWS_SECRET_KEY = os.getenv("AWS_SECRET_ACCESS_KEY") or os.getenv(
        "MINIO_ROOT_PASSWORD"
    )

    _raw_endpoint = os.getenv("MINIO_ENDPOINT")

    if _raw_endpoint:
        if not _raw_endpoint.startswith("http"):
            S3_ENDPOINT = f"http://{_raw_endpoint}"
        else:
            S3_ENDPOINT = _raw_endpoint
    else:
        # Default to None (implies real AWS S3)
        S3_ENDPOINT = None

    BUCKET_NAME = os.getenv("DATA_LAKE_BUCKET", "rawg-lake")

    # Defaults
    PAGE_SIZE = 40

    def validate(self):
        if not self.RAWG_API_KEY:
            raise ValueError("Missing RAWG_API_KEY in environment variables.")
        if not self.AWS_ACCESS_KEY or not self.AWS_SECRET_KEY:
            raise ValueError("Missing Storage Credentials (AWS or MINIO).")
        return True


config = Config()
