#!/bin/bash

# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the terms described in the LICENSE file in
# the root directory of this source tree.

# Script to generate the Python SDK using openapi-generator-cli with custom templates
#
# This script generates a Python client SDK from the OpenAPI specification
# using custom templates that create a convenient LlamaStackClient wrapper class.

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Paths
OPENAPI_SPEC="${1:-$SCRIPT_DIR/openapi.generator.yml}"
CONFIG_FILE="$SCRIPT_DIR/openapi-config.json"
TEMPLATE_DIR="$SCRIPT_DIR/templates/python"
OUTPUT_DIR="${2:-$SCRIPT_DIR/sdks/python}"

echo -e "${BLUE}Llama Stack Python SDK Generator${NC}"
echo "=================================="
echo ""
echo "Usage: $0 [OPENAPI_SPEC] [OUTPUT_DIR]"
echo "  OPENAPI_SPEC: Path to OpenAPI spec (default: openapi.generator.yml)"
echo "  OUTPUT_DIR:   Output directory (default: sdks/python)"
echo ""

# Check if openapi-generator-cli is installed
if ! command -v openapi-generator-cli &> /dev/null; then
    echo -e "${RED}Error: openapi-generator-cli is not installed${NC}"
    echo ""
    echo "Please install it using one of the following methods:"
    echo ""
    echo "1. Using npm (recommended):"
    echo "   npm install -g @openapitools/openapi-generator-cli"
    echo ""
    echo "2. Using Homebrew (macOS):"
    echo "   brew install openapi-generator"
    echo ""
    echo "3. Download the JAR file:"
    echo "   Visit https://openapi-generator.tech/docs/installation"
    exit 1
fi

# Verify files exist
if [ ! -f "$OPENAPI_SPEC" ]; then
    echo -e "${RED}Error: OpenAPI spec not found at $OPENAPI_SPEC${NC}"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Config file not found at $CONFIG_FILE${NC}"
    exit 1
fi

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo -e "${RED}Error: Template directory not found at $TEMPLATE_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} OpenAPI Spec: $OPENAPI_SPEC"
echo -e "${GREEN}✓${NC} Config File: $CONFIG_FILE"
echo -e "${GREEN}✓${NC} Template Dir: $TEMPLATE_DIR"
echo -e "${GREEN}✓${NC} Output Dir: $OUTPUT_DIR"
echo ""

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}Generating Python SDK...${NC}"
echo ""

# Run openapi-generator-cli
openapi-generator-cli generate \
    -i "$OPENAPI_SPEC" \
    -g python \
    -c "$CONFIG_FILE" \
    -t "$TEMPLATE_DIR" \
    -o "$OUTPUT_DIR" \
    --additional-properties=generateSourceCodeOnly=false

echo ""
echo -e "${GREEN}✓ Python SDK generated successfully!${NC}"
echo ""

# Copy the lib/ directory as-is (contains non-templated utility modules)
echo -e "${BLUE}Copying lib/ directory...${NC}"
if [ -d "$TEMPLATE_DIR/lib" ]; then
    cp -r "$TEMPLATE_DIR/lib" "$OUTPUT_DIR/llama_stack_client/"
    echo -e "${GREEN}✓${NC} lib/ directory copied successfully"
else
    echo -e "${RED}Warning: lib/ directory not found at $TEMPLATE_DIR/lib${NC}"
fi
echo ""

# Check if api-hierarchy.yml exists and patch the APIs
HIERARCHY_FILE="$SCRIPT_DIR/api-hierarchy.yml"
PATCH_SCRIPT="$SCRIPT_DIR/patch_api_hierarchy.py"

if [ -f "$HIERARCHY_FILE" ] && [ -f "$PATCH_SCRIPT" ]; then
    echo -e "${BLUE}Patching API hierarchy...${NC}"
    echo ""
    python3 "$PATCH_SCRIPT" --hierarchy "$HIERARCHY_FILE" --sdk-dir "$OUTPUT_DIR"
    echo ""
fi

echo "OpenAPI Spec: $OPENAPI_SPEC"
echo "Output directory: $OUTPUT_DIR"
echo ""
echo "To install the SDK, run:"
echo "  cd $OUTPUT_DIR"
echo "  pip install -e ."
echo ""
echo "Example usage:"
echo "  from llama_stack_client import Configuration, LlamaStackClient"
echo "  config = Configuration(host=\"http://localhost:8000\")"
echo "  client = LlamaStackClient(config)"
echo "  # Use client.chat, client.agents, etc."
