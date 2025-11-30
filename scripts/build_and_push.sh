set -e

if [ -z "$AWS_REGION" ]; then
    export AWS_REGION="us-east-1"
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "=========================================================="
echo " BUILDING AND PUSHING DOCKER IMAGES"
echo "   Region: $AWS_REGION"
echo "   Registry: $ECR_URL"
echo "=========================================================="

#  Login to ECR
echo ">> Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL

echo ">> [1/2] Building Ingestion..."
docker build -t ${PROJECT_NAME}-ingestion ./ingestion
docker tag ${PROJECT_NAME}-ingestion:latest ${ECR_URL}/${PROJECT_NAME}-ingestion:latest

echo ">> Pushing Ingestion..."
docker push ${ECR_URL}/${PROJECT_NAME}-ingestion:latest

echo "[2/2] Building Analytics..."
docker build -t ${PROJECT_NAME}-analytics ./analytics
docker tag ${PROJECT_NAME}-analytics:latest $ECR_URL/${PROJECT_NAME}-analytics:latest

echo ">> Pushing Analytics..."
docker push $ECR_URL/${PROJECT_NAME}-analytics:latest

echo ">> All images pushed successfully!"
