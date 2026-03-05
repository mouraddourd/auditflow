#!/bin/bash
# Generate PowerSync configuration from template with environment variables
# Usage: ./generate-powersync-config.sh [dev|prod]

set -e

ENV=${1:-dev}
TEMPLATE_FILE="powersync.template.yaml"
OUTPUT_FILE="powersync.yaml"

if [ "$ENV" = "prod" ]; then
    OUTPUT_FILE="powersync.prod.yaml"
    echo "Generating production PowerSync config..."
else
    echo "Generating development PowerSync config..."
fi

# Check if .env exists
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    exit 1
fi

# Export variables from .env for envsubst
export $(grep -v '^#' .env | xargs)

# Generate config
echo "Generating $OUTPUT_FILE from $TEMPLATE_FILE..."
envsubst < "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "✅ Config generated: $OUTPUT_FILE"
echo ""
echo "Preview (first 10 lines):"
head -10 "$OUTPUT_FILE"
