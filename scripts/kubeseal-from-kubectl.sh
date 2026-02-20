#r  !/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_PATH="$SCRIPT_DIR/sealed-secrets-pub.pem"

usage() {
  cat <<'USAGE'
Usage: kubeseal-from-kubectl.sh [--subcommand <generic|docker-registry|tls>] [kubectl-create-secret-args]

Prompts for secret name and namespace, builds a secret via kubectl create secret,
and seals it using the public cert at scripts/pub-sealed-secrets.pem.

Examples:
  kubeseal-from-kubectl.sh --from-literal=password=supersecret
  kubeseal-from-kubectl.sh --subcommand tls --cert=./tls.crt --key=./tls.key

Notes:
  - Output is a sealed secret YAML written to stdout.
  - This script does not apply anything to the cluster.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -f "$CERT_PATH" ]]; then
  echo "ERROR: missing cert at $CERT_PATH" >&2
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "ERROR: kubectl not found in PATH" >&2
  exit 1
fi

if ! command -v kubeseal >/dev/null 2>&1; then
  echo "ERROR: kubeseal not found in PATH" >&2
  exit 1
fi

SUBCOMMAND="generic"
if [[ "${1:-}" == "--subcommand" ]]; then
  if [[ -z "${2:-}" ]]; then
    echo "ERROR: --subcommand requires a value" >&2
    exit 1
  fi
  SUBCOMMAND="$2"
  shift 2
fi

if [[ -z "$SECRET_NAME" ]]; then
  read -r -p "Secret name: " SECRET_NAME
  if [[ -z "$SECRET_NAME" ]]; then
    echo "ERROR: secret name is required" >&2
    exit 1
  fi
fi

if [[ -z "$NAMESPACE" ]]; then
  read -r -p "Namespace: " NAMESPACE
  if [[ -z "$NAMESPACE" ]]; then
    echo "ERROR: namespace is required" >&2
    exit 1
  fi
fi

kubectl create secret "$SUBCOMMAND" "$SECRET_NAME" \
  --namespace "$NAMESPACE" \
  --dry-run=client -o yaml \
  "$@" \
  | kubeseal --cert "$CERT_PATH" --format yaml

