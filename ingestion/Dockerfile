FROM python:3.12-slim

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir .

RUN useradd -m appuser && chown -R appuser /app
USER appuser

ENTRYPOINT ["python", "main.py"]
CMD ["--help"]
