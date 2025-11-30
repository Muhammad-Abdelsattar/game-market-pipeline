# 📊 Data Warehouse & Analytics 

The Data Warehouse is designed to optimize for **scalability** and **schema evolution**. Since the source data is complex, nested JSON, we utilize a "Schema-on-Read" approach.

## Layered Architecture

### 1. Raw Layer (External Tables)
*   **Location:** `GAME_MARKET_DB.RAW`
*   **Technology:** Snowflake External Tables / DuckDB `read_json_auto`.
*   **Description:** Virtual tables pointing directly to S3 files.
*   **Schema:** Single column (`value` or `json_blob`) containing the full JSON object.
*   **Benefit:** Zero-copy ingestion. If the API adds a new field, we don't need to run `ALTER TABLE`. It's immediately available in the JSON blob.

### 2. Staging Layer (`stg_`)
*   **Materialization:** Views.
*   **Function:**
    *   **Flattening:** Explodes nested arrays (e.g., A Game has many Genres) into rows.
    *   **Type Casting:** Converts JSON strings to `INT`, `DATE`, `BOOLEAN`.
    *   **Renaming:** Maps API keys (e.g., `rating_top`) to business terms (`best_rating`).
*   **Logic:** Uses custom macros (`json_select`, `explode_json`) to handle cross-db SQL syntax.

### 3. Marts Layer (`dim_` / `fct_`)
*   **Materialization:** Tables (Incremental).
*   **Schema:** Star Schema.
*   **Entities:**
    *   `fct_games`: Central fact table containing game metrics (ratings, playtime).
    *   `dim_developers`, `dim_publishers`: Dimensions joining to the fact.
    *   `bridge_game_genres`: handling the Many-to-Many relationship between Games and Genres.

## Data Warehouse Design

![Data Model](./assets/DWH.png)
