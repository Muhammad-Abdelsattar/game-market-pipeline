set -e

# Define paths relative to the script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
AWS_DIR="$SCRIPT_DIR/../infrastructure/aws"
SNOWFLAKE_DIR="$SCRIPT_DIR/../infrastructure/snowflake"

echo "=========================================================="
echo "GAME PIPELINE INFRASTRUCTURE DEPLOYMENT"
echo "=========================================================="

# Check if environment variables are set
if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
    echo "❌ Error: AWS credentials not found in environment."
    exit 1
fi
if [[ -z "$TF_VAR_snowflake_account" ]]; then
    echo "❌ Error: TF_VAR_snowflake_account not found."
    exit 1
fi

echo "Phase 1: AWS Base Layer (Creating Bucket & Role)"
cd "$AWS_DIR"
terraform init -upgrade
# We pass empty strings for Snowflake ID to create the role with a placeholder first
terraform apply -auto-approve \
    -var="snowflake_iam_user=" \
    -var="snowflake_external_id="

# Capture Outputs
AWS_ROLE_ARN=$(terraform output -raw snowflake_role_arn)
S3_BUCKET=$(terraform output -raw s3_bucket_name)

echo "✅ AWS Base Deployed."
echo "   -> Role: $AWS_ROLE_ARN"
echo "   -> Bucket: $S3_BUCKET"

echo "Phase 2: Snowflake Integration (Creating Storage Object)"
cd "$SNOWFLAKE_DIR"
terraform init -upgrade
terraform apply -auto-approve \
    -var="aws_role_arn=$AWS_ROLE_ARN" \
    -var="s3_bucket_name=$S3_BUCKET"

# Capture Outputs
SF_USER=$(terraform output -raw storage_aws_iam_user_arn)
SF_EXT_ID=$(terraform output -raw storage_aws_external_id)

echo "✅ Snowflake Configured."
echo "   -> SF IAM User: $SF_USER"
echo "   -> SF External ID: $SF_EXT_ID"

echo "Phase 3: Securing Handshake (Locking AWS Role)"
cd "$AWS_DIR"
# Now we run AWS apply again, but this time WITH the Snowflake variables
terraform apply -auto-approve \
    -var="snowflake_iam_user=$SF_USER" \
    -var="snowflake_external_id=$SF_EXT_ID"

echo "=========================================================="
echo "🎉 DEPLOYMENT COMPLETE & SECURED"
echo "=========================================================="
