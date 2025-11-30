FROM python:3.12-slim

RUN apt-get update && apt-get install -y git

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy dbt project
# Install system dependencies (git is needed for dbt packages)
COPY . . 

RUN dbt deps
