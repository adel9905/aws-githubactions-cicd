#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "${ROOT_DIR}/dist"
cp -R "${ROOT_DIR}/app/." "${ROOT_DIR}/dist/"
echo "Built dist/ from app/"
