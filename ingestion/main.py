# ingestion/main.py
import sys
import argparse
from datetime import datetime
from src.config import config
from src.client import RAWGClient
from src.storage import S3Writer
from src.logger import get_logger

logger = get_logger("IngestionMain")


# Update function signature to accept dates
def run_pipeline(
    endpoint: str, max_pages: int, start_date: str = None, end_date: str = None
):
    config.validate()
    client = RAWGClient()
    writer = S3Writer()

    run_date = datetime.now().strftime("%Y-%m-%d")

    # 1. Construct Date Filters
    # RAWG API expects 'updated' in format "2023-01-01,2023-12-31"
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

        try:
            # 2. Pass the api_params here
            data = client.fetch_page(endpoint, page=current_page, params=api_params)

            if not data.get("results"):
                logger.info("No results found. Stopping.")
                break

            # Load
            # If we are doing a date filter, we might want to save it in a specific "incremental" folder
            # But for now, keeping it in raw/ is fine, the run_date partition separates them.
            file_path = f"raw/{endpoint}/run_date={run_date}/page_{current_page}.json"
            writer.save_json(data, file_path)

            if not data.get("next"):
                logger.info("End of dataset reached.")
                break

            current_page += 1

        except Exception as e:
            logger.critical(f"Pipeline failed on page {current_page}: {e}")
            sys.exit(1)

    logger.info(f"Ingestion complete. Processed {current_page - 1} pages.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--endpoint", type=str, default="games")
    parser.add_argument("--max_pages", type=int, default=5)

    # New Arguments
    parser.add_argument("--start_date", type=str, help="YYYY-MM-DD", default=None)
    parser.add_argument("--end_date", type=str, help="YYYY-MM-DD", default=None)

    args = parser.parse_args()

    run_pipeline(args.endpoint, args.max_pages, args.start_date, args.end_date)
