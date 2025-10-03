#!/usr/bin/env bash
set -euo pipefail

COMMAND=${1:-up}
COMPOSE_FILE=${COMPOSE_FILE:-docker-compose.yml}

ensure_dirs() {
  mkdir -p PVC/mongo_data PVC/mongo_config
}

case "$COMMAND" in
  up)
    ensure_dirs
    docker compose -f "$COMPOSE_FILE" up -d
    echo "MongoDB is starting via docker compose. Use './run.sh logs' to tail logs."
    ;;
  down)
    docker compose -f "$COMPOSE_FILE" down
    ;;
  logs)
    docker compose -f "$COMPOSE_FILE" logs -f mongo
    ;;
  *)
    echo "Unknown command: $COMMAND" >&2
    echo "Usage: $0 [up|down|logs]" >&2
    exit 1
    ;;
esac
