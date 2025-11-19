FROM python:3.12-slim

WORKDIR /app

COPY ingestion/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# We copy the whole folder so the structure ingestion/src/... is preserved
COPY ingestion/ .

# Create a non-root user for security (Best Practice)
RUN useradd -m appuser && chown -R appuser /app
USER appuser

# We will override this via Docker Compose or CLI
ENTRYPOINT ["python", "main.py"]
CMD ["--help"]
