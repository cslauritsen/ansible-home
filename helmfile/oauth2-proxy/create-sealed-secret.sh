#!/bin/bash
set -e

# This script will:
# 1. Retrieve secrets from 1Password
# 2. Create a Kubernetes secret
# 3. Seal it with kubeseal
# 4. Save it to a file

echo "Retrieving secrets from 1Password..."
CLIENT_ID=$(op read --no-newline "op://Private/4vowpk2pjbbegc4wnwrz6s4mg4/client-id")
CLIENT_SECRET=$(op read --no-newline "op://Private/4vowpk2pjbbegc4wnwrz6s4mg4/client-secret")
COOKIE_SECRET=$(op read --no-newline "op://Private/4vowpk2pjbbegc4wnwrz6s4mg4/cookie-secret")

echo "Creating sealed secret..."
kubectl create secret generic oauth2-proxy-secrets \
  --namespace=oauth2-proxy \
  --from-literal=client-id="$CLIENT_ID" \
  --from-literal=client-secret="$CLIENT_SECRET" \
  --from-literal=cookie-secret="$COOKIE_SECRET" \
  --dry-run=client -o yaml | \
  kubeseal --controller-name=sealed-secrets-controller \
    --controller-namespace=kube-system \
    --format=yaml \
    > "$(dirname "$0")/rsrc/oauth2-proxy-sealed-secret.yaml"

echo "Sealed secret created at: rsrc/oauth2-proxy-sealed-secret.yaml"
echo "You can now safely commit this file to git."

