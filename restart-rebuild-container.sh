#!/bin/bash
set -e

echo ">>> Stopping ARK container..."
docker compose stop ark-server

echo ">>> Removing ARK container..."
docker compose rm -f ark-server

echo ">>> Pruning unused images..."
docker image prune -f

echo ">>> Building new image without cache..."
docker compose build --no-cache ark-server

echo ">>> Starting new ARK container..."
docker compose up -d ark-server

echo ">>> View ARK container logs..."
docker logs -f ark-server