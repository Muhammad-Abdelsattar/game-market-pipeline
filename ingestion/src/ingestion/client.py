import requests
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
from .config import config
from .logger import get_logger

logger = get_logger("RAWGClient")

class RAWGClient:
    def __init__(self):
        self.base_url = config.RAWG_BASE_URL
        self.api_key = config.RAWG_API_KEY
        self.session = requests.Session()

    @retry(
        stop=stop_after_attempt(5),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type((requests.exceptions.RequestException, requests.exceptions.Timeout))
    )
    def fetch_page(self, endpoint: str, page: int, page_size: int = config.PAGE_SIZE, params: dict = None):
        """
        Fetches a single page of data. 
        Retries 5 times with exponential backoff if network fails.
        """
        if params is None:
            params = {}
        
        # Merge default auth params
        query_params = {
            "key": self.api_key,
            "page": page,
            "page_size": page_size,
            **params
        }

        url = f"{self.base_url}/{endpoint}"
        
        logger.info(f"Fetching {endpoint} - Page {page}...")
        
        response = self.session.get(url, params=query_params, timeout=10)
        
        if response.status_code == 200:
            return response.json()


        elif response.status_code == 404:
            # 404 on a list endpoint usually means "Page out of range".
            # We return an empty structure so the pipeline loop terminates gracefully.
            logger.info(f"Page {page} not found (404). Assuming end of dataset.")
            return {"results": [], "next": None}
        elif response.status_code == 429:
            logger.warning("Rate limit hit (429).")
            # In a real production script, we might sleep here manually or let tenacity handle it if we raise an error
            response.raise_for_status()
        else:
            logger.error(f"API Error {response.status_code}: {response.text}")
            response.raise_for_status()
