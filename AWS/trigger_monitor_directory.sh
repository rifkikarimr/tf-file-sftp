#!/bin/bash

DIRECTORY="/H2H-ASG/Ready to Encrypt/"
LAMBDA_FUNCTION_NAME="FuncEncryptSap"

while inotifywait -e create "$DIRECTORY"; do
    echo "New file detected in $DIRECTORY"
    
    # Trigger the Lambda function
    aws lambda invoke \
        --function-name "$LAMBDA_FUNCTION_NAME" \
        --payload '{}' \
        /tmp/lambda_output.json
    
    echo "Lambda function triggered"
done
