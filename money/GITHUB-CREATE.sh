#!/usr/bin/env bash
set -uo pipefail
exec node "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/github-create.js"
