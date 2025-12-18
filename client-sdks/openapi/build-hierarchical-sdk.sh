#!/bin/bash

# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the terms described in the LICENSE file in
# the root directory of this source tree.

# Complete workflow to build hierarchical Python SDK
#
# This script:
# 1. Processes the OpenAPI spec to extract tag hierarchies
# 2. Generates the Python SDK using the processed spec
# 3. Patches the generated SDK to add hierarchical properties

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
SOURCE_SPEC="${1:-$SCRIPT_DIR/openapi.generator.yml}"
OUTPUT_DIR="${2:-$SCRIPT_DIR/sdks/python}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Llama Stack Hierarchical Python SDK Builder                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Process OpenAPI spec
echo -e "${YELLOW}Step 1/3: Processing OpenAPI spec to extract hierarchy...${NC}"
echo ""

python3 "$SCRIPT_DIR/process_openapi_hierarchy.py" \
    --source "$SOURCE_SPEC" \
    --output "$SCRIPT_DIR/openapi-processed.yml" \
    --hierarchy "$SCRIPT_DIR/api-hierarchy.yml"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to process OpenAPI spec${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ OpenAPI spec processed${NC}"
echo ""

# Step 2: Generate Python SDK
echo -e "${YELLOW}Step 2/3: Generating Python SDK...${NC}"
echo ""

"$SCRIPT_DIR/generate-python-sdk.sh" \
    "$SCRIPT_DIR/openapi-processed.yml" \
    "$OUTPUT_DIR"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to generate Python SDK${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Python SDK generated${NC}"
echo ""

# Step 3: Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Build Complete!                                               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Generated files:"
echo "  📄 openapi-processed.yml  - Processed OpenAPI spec"
echo "  📄 api-hierarchy.yml      - API hierarchy structure"
echo "  📁 $OUTPUT_DIR            - Generated Python SDK"
echo ""
echo "To install the SDK:"
echo "  cd $OUTPUT_DIR"
echo "  pip install -e ."
echo ""
echo "The SDK now supports hierarchical API access:"
echo "  client.chat.completions.create(...)  # Nested structure"
echo ""
