#!/usr/bin/env bash
# Notion API helper script
# Usage: ./notion.sh [command] [args]

NOTION_TOKEN="${NOTION_TOKEN:-}"
NOTION_VERSION="2022-06-28"
API_BASE="https://api.notion.com/v1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() {
  echo -e "${RED}Error: $1${NC}" >&2
  exit 1
}

success() {
  echo -e "${GREEN}$1${NC}"
}

warn() {
  echo -e "${YELLOW}Warning: $1${NC}"
}

# Make a request to Notion API
notion_request() {
  local method="$1"
  local endpoint="$2"
  local data="$3"

  if [ -z "$NOTION_TOKEN" ]; then
    error "NOTION_TOKEN is not set (export NOTION_TOKEN=...); do not store it in files."
  fi

  local curl_cmd="curl -s -X $method"
  curl_cmd+=" -H 'Authorization: Bearer $NOTION_TOKEN'"
  curl_cmd+=" -H 'Notion-Version: $NOTION_VERSION'"
  curl_cmd+=" -H 'Content-Type: application/json'"

  if [ -n "$data" ]; then
    curl_cmd+=" -d '$data'"
  fi

  curl_cmd+=" \"${API_BASE}${endpoint}\""

  eval $curl_cmd
}

# List all databases
list_databases() {
  echo "Fetching databases..."
  notion_request "POST" "/search" '{"filter":{"property":"object","value":"database"}}'
}

# Query a specific database
query_database() {
  local database_id="$1"
  if [ -z "$database_id" ]; then
    error "Database ID required"
  fi
  echo "Querying database: $database_id"
  notion_request "POST" "/databases/$database_id/query"
}

# Get page content
get_page() {
  local page_id="$1"
  if [ -z "$page_id" ]; then
    error "Page ID required"
  fi
  echo "Fetching page: $page_id"
  notion_request "GET" "/pages/$page_id"
}

# Search content
search() {
  local query="$1"
  if [ -z "$query" ]; then
    error "Search query required"
  fi
  echo "Searching for: $query"
  notion_request "POST" "/search" "{\"query\":\"$query\"}"
}

# Show usage
show_usage() {
  cat << EOF
Notion API Helper

Usage: ./notion.sh [command] [args]

Commands:
  list-databases      List all accessible databases
  query <db-id>       Query a specific database
  page <page-id>      Get page content
  search <query>      Search for content

Examples:
  ./notion.sh list-databases
  ./notion.sh query 1234567890abcdef
  ./notion.sh page 1234567890abcdef
  ./notion.sh search "my project"

EOF
}

# Main command router
case "$1" in
  list-databases)
    list_databases
    ;;
  query)
    query_database "$2"
    ;;
  page)
    get_page "$2"
    ;;
  search)
    search "$2"
    ;;
  *)
    show_usage
    exit 1
    ;;
esac
