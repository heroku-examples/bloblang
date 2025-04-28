#!/bin/bash

# blobl.sh
# Run a Bloblang mapping using Benthos, handling both .json and .jsonl files smartly.

set -e

# Usage function
usage() {
  echo ""
  echo "Usage: blobl.sh [-m mapping_string | -f mapping_file] [-i input_file] [-o output_file]"
  echo ""
  echo "Options:"
  echo "  -m, --mapping       Inline Bloblang mapping string."
  echo "  -f, --mapping-file  Path to a .blobl file containing a mapping."
  echo "  -i, --input         Input file (.json or .jsonl). Defaults to stdin."
  echo "  -o, --output        Output file. Defaults to stdout."
  echo "  -h, --help          Show this help message."
  echo ""
  echo "Notes:"
  echo "  - Either -m or -f must be specified, but not both."
  echo "  - If input is a .json file, it will be automatically converted to .jsonl internally."
  echo "  - The script automatically cleans up temporary files created during conversion."
  echo ""
}

MAPPING=""
MAPPING_FILE=""
INPUT=""
OUTPUT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -m|--mapping)
      MAPPING="$2"
      shift 2
      ;;
    -f|--mapping-file)
      MAPPING_FILE="$2"
      shift 2
      ;;
    -i|--input)
      INPUT="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Validate mapping arguments
if [ -n "$MAPPING" ] && [ -n "$MAPPING_FILE" ]; then
  echo "Error: Specify either -m (mapping string) OR -f (mapping file), not both."
  usage
  exit 1
fi

if [ -z "$MAPPING" ] && [ -z "$MAPPING_FILE" ]; then
  echo "Error: A mapping (-m) or mapping file (-f) is required."
  usage
  exit 1
fi

# Validate input
TEMP_INPUT=""
if [ -n "$INPUT" ]; then
  if [[ "$INPUT" == *.json ]]; then
    # Convert pretty .json to .jsonl temporarily
    TEMP_INPUT=$(mktemp)
    jq -c '.[]?' "$INPUT" > "$TEMP_INPUT"
    INPUT_CMD="cat \"$TEMP_INPUT\""
  else
    INPUT_CMD="cat \"$INPUT\""
  fi
else
  INPUT_CMD="cat" # stdin
fi

# Choose output destination
if [ -n "$OUTPUT" ]; then
  OUTPUT_CMD="> \"$OUTPUT\""
else
  OUTPUT_CMD="cat" # stdout
fi

# Build benthos blobl command
BLOBL_CMD="benthos blobl --pretty"
if [ -n "$MAPPING" ]; then
  BLOBL_CMD="$BLOBL_CMD \"$MAPPING\""
else
  BLOBL_CMD="$BLOBL_CMD -f \"$MAPPING_FILE\""
fi

# Execute
(eval "$INPUT_CMD"; sleep 0.1) | eval $BLOBL_CMD | eval "$OUTPUT_CMD"

# Cleanup temporary file
if [ -n "$TEMP_INPUT" ] && [ -f "$TEMP_INPUT" ]; then
  rm -f "$TEMP_INPUT"
fi
