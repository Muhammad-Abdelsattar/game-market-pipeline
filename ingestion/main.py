import argparse
from ingestion.pipeline import run_pipeline


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--endpoint", type=str, default="games")
    parser.add_argument("--max_pages", type=int, default=5)

    # New Arguments
    parser.add_argument("--start_date", type=str, help="YYYY-MM-DD", default=None)
    parser.add_argument("--end_date", type=str, help="YYYY-MM-DD", default=None)

    args = parser.parse_args()

    run_pipeline(args.endpoint, args.max_pages, args.start_date, args.end_date)
