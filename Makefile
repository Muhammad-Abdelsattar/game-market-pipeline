# ==============================================================================
# VARIABLES
# ==============================================================================
COMPOSE_FILE=local_ops/docker-compose.yml
ENV_FILE=.env

# ==============================================================================
# HELPERS
# ==============================================================================
.PHONY: help
help:
	@echo "🎮 Game Market Pipeline (Dagster) - Management Commands"
	@echo "----------------------------------------------------------------"
	@echo "  make start    : Setup folders and start Dagster (Detached)"
	@echo "  make down     : Stop all containers"
	@echo "  make logs     : Tail logs for all containers"
	@echo "  make shell    : Open a bash shell inside the Dagster Daemon"
	@echo "  make dbt      : Run dbt commands manually inside the container"
	@echo "  make clean    : ⚠️  Stop containers and DELETE ALL DATA (DBs, Logs)"
	@echo "----------------------------------------------------------------"

# ==============================================================================
# INITIALIZATION & STARTUP
# ==============================================================================
.PHONY: init
init:
	@echo "🛠️  Initializing configuration..."
	@# 1. Create .env if it doesn't exist
	@touch $(ENV_FILE)
	
	@# 2. Create the Central Data Directory structure
	@#    These persist your Database, MinIO files, and DuckDB warehouse
	@echo "📂 Creating data directories..."
	@mkdir -p local_ops/data/minio \
	          local_ops/data/postgres \
	          local_ops/data/warehouse

.PHONY: start
start: init
	@echo "🚀 Starting Dagster Monolith..."
	@# We export .env so Docker Compose picks up the variables
	@export $$(grep -v '^#' $(ENV_FILE) | xargs) && \
	docker compose -f $(COMPOSE_FILE) up -d --build
	@echo "✅ Services started!"
	@echo "   - Dagster UI:  http://localhost:3000"
	@echo "   - MinIO UI:    http://localhost:9001"

# ==============================================================================
# MANAGEMENT
# ==============================================================================
.PHONY: down
down:
	@echo "🛑 Stopping services..."
	docker compose -f $(COMPOSE_FILE) down

.PHONY: logs
logs:
	docker compose -f $(COMPOSE_FILE) logs -f

.PHONY: shell
shell:
	@echo "🐚 Entering Dagster Daemon Container..."
	@echo "   (You can run 'dagster job list' or python scripts here)"
	docker exec -it local_ops-dagster-daemon-1 bash

.PHONY: dbt
dbt:
	@echo "running dbt..."
	docker exec -it local_ops-dagster-daemon-1 bash -c "cd /opt/dagster/analytics && dbt build"

# ==============================================================================
# CLEANUP
# ==============================================================================
.PHONY: clean
clean: down
	@echo "🧹 Cleaning up ALL data..."
	@# We use sudo because Docker creates files as root inside these folders
	sudo rm -rf local_ops/data
	@echo "✨ Clean complete. Project is reset."
