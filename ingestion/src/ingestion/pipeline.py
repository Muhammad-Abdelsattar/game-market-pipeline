import sys
from datetime import datetime, timedelta
from .config import config
from .client import RAWGClient
from .storage import S3Writer
from .logger import get_logger

logger = get_logger("IngestionMain")


def run_pipeline(
    endpoint: str, max_pages: int, start_date: str = None, end_date: str = None
):
    config.validate()
    client = RAWGClient()
    writer = S3Writer()

    # This defines the "Partition" folder in S3 (When the job ran)
    run_date = datetime.now().strftime("%Y-%m-%d")

    # LOGIC: If Step Functions sends no args, default to "Yesterday's Data"
    if not start_date and not end_date:
        yesterday = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
        start_date = yesterday
        end_date = yesterday
        logger.info(f"No dates provided. Defaulting to incremental mode: {yesterday}")

    # Construct Date Filters for the API
    api_params = {}
    if start_date and end_date:
        api_params["updated"] = f"{start_date},{end_date}"
        logger.info(f"Filtering data updated between {start_date} and {end_date}")

    current_page = 1

    logger.info(f"Starting ingestion for: '{endpoint}'")

    while True:
        if max_pages > 0 and current_page > max_pages:
            logger.info(f"Reached max_pages limit ({max_pages}). Stopping.")
            break

        # Define the path once per loop iteration
        file_path = f"raw/{endpoint}/run_date={run_date}/page_{current_page}.json"

        # CHECKPOINT: Idempotency Check
        if writer.exists(file_path):
            logger.info(f"Page {current_page} exists in S3. Skipping.")
            current_page += 1
            continue

        try:
            # API Call
            data = client.fetch_page(endpoint, page=current_page, params=api_params)

            if not data.get("results"):
                logger.info("No results found. Stopping.")
                break

            # Save to S3
            writer.save_json(data, file_path)

            if not data.get("next"):
                logger.info("End of dataset reached.")
                break

            current_page += 1

        except Exception as e:
            logger.critical(f"Pipeline failed on page {current_page}: {e}")
            sys.exit(1)

    logger.info(f"Ingestion complete. Processed {current_page - 1} pages.")