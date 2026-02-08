# Phase 5 Checklist - Convert Secrets to Sealed Secrets

## Overview
Convert all 1Password-managed secrets (`op://` references) to Sealed Secrets so applications can be deployed via GitOps without requiring 1Password CLI on the server.

## Prerequisites
- [x] Sealed Secrets controller deployed (Phase 1)
- [x] Public certificate available: `pub-sealed-secrets.pem`
- [x] kubeseal CLI installed
- [x] ArgoCD applications created (Phase 4)

## Step-by-Step Process

### 1. Identify All Secrets
```bash
# Search for all op:// references
cd /Users/csl04r/repos/cslauritsen/ansible-home
grep -r "op://" helmfile/ | grep -v ".git"
```

Expected secrets:
- [ ] Grafana Cloud credentials
- [ ] OAuth2-proxy client secrets
- [ ] Cert-manager Cloudflare API token
- [ ] MongoDB passwords
- [ ] RabbitMQ passwords
- [ ] Kafka credentials (if any)
- [ ] James email server secrets (if any)

### 2. For Each Secret, Follow This Pattern

#### 2.1 Extract Secret from 1Password
```bash
# Example for Grafana
op read "op://Private/grafana-cloud-api-key/credential"
```

#### 2.2 Create Kubernetes Secret YAML
```bash
# Create temporary secret (not committed)
cat > /tmp/grafana-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: grafana-cloud-credentials
  namespace: grafana
type: Opaque
stringData:
  api-key: "YOUR_SECRET_HERE"
  url: "https://grafana.net"
EOF
```

#### 2.3 Seal the Secret
```bash
# Seal it using the public certificate
kubeseal --format=yaml \
  --cert=pub-sealed-secrets.pem \
  < /tmp/grafana-secret.yaml \
  > helmfile/grafana/sealed-secret.yaml
```

#### 2.4 Update Helmfile
Remove `op://` reference and reference the sealed secret instead.

#### 2.5 Clean Up Temporary File
```bash
rm /tmp/grafana-secret.yaml
```

#### 2.6 Commit Sealed Secret
```bash
git add helmfile/grafana/sealed-secret.yaml
git commit -m "Add sealed secret for Grafana"
```

---

## Application-Specific Instructions

### Grafana

**Secrets Needed:**
- Grafana Cloud API key
- Grafana Cloud URL
- Admin password

**Files to Check:**
- `helmfile/grafana/helmfile.yaml`

**Steps:**
```bash
# 1. Extract from 1Password
GRAFANA_API_KEY=$(op read "op://Private/grafana-cloud-api-key/credential")
GRAFANA_URL=$(op read "op://Private/grafana-cloud-url/url")
ADMIN_PASSWORD=$(op read "op://Private/grafana-admin/password")

# 2. Create secret
cat > /tmp/grafana-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: grafana-secrets
  namespace: grafana
type: Opaque
stringData:
  api-key: "$GRAFANA_API_KEY"
  url: "$GRAFANA_URL"
  admin-password: "$ADMIN_PASSWORD"
EOF

# 3. Seal it
kubeseal --format=yaml --cert=pub-sealed-secrets.pem \
  < /tmp/grafana-secret.yaml > helmfile/grafana/sealed-secret.yaml

# 4. Update helmfile.yaml to reference this secret
# 5. Commit
rm /tmp/grafana-secret.yaml
git add helmfile/grafana/sealed-secret.yaml
```

---

### OAuth2-Proxy

**Secrets Needed:**
- Client ID
- Client Secret
- Cookie Secret

**Files to Check:**
- `helmfile/oauth2-proxy/helmfile.yaml`
- `helmfile/oauth2-proxy/rsrc/secret.yaml.gotmpl`

**Steps:**
```bash
# 1. Extract from 1Password
CLIENT_ID=$(op read "op://Private/oauth2-proxy/client-id")
CLIENT_SECRET=$(op read "op://Private/oauth2-proxy/client-secret")
COOKIE_SECRET=$(op read "op://Private/oauth2-proxy/cookie-secret")

# 2. Create secret
cat > /tmp/oauth2-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: oauth2-proxy-secrets
  namespace: oauth2-proxy
type: Opaque
stringData:
  client-id: "$CLIENT_ID"
  client-secret: "$CLIENT_SECRET"
  cookie-secret: "$COOKIE_SECRET"
EOF

# 3. Seal it
kubeseal --format=yaml --cert=pub-sealed-secrets.pem \
  < /tmp/oauth2-secret.yaml > helmfile/oauth2-proxy/sealed-secret.yaml

# 4. Update helmfile to use existingSecret
# 5. Commit
rm /tmp/oauth2-secret.yaml
git add helmfile/oauth2-proxy/sealed-secret.yaml
```

---

### Cert-Manager

**Secrets Needed:**
- Cloudflare API token

**Files to Check:**
- `helmfile/cert-manager/rsrc/secret.yaml.gotmpl`

**Steps:**
```bash
# 1. Extract from 1Password
CF_API_TOKEN=$(op read "op://Private/cloudflare-api-token/credential")

# 2. Create secret
cat > /tmp/cloudflare-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token
  namespace: cert-manager
type: Opaque
stringData:
  api-token: "$CF_API_TOKEN"
EOF

# 3. Seal it
kubeseal --format=yaml --cert=pub-sealed-secrets.pem \
  < /tmp/cloudflare-secret.yaml > helmfile/cert-manager/rsrc/sealed-cloudflare-secret.yaml

# 4. Remove .gotmpl file, update issuer to reference sealed secret
# 5. Commit
rm /tmp/cloudflare-secret.yaml
git add helmfile/cert-manager/rsrc/sealed-cloudflare-secret.yaml
```

---

### MongoDB

**Secrets Needed:**
- Root password
- Replica set key

**Files to Check:**
- `helmfile/mongodb/helmfile.yaml`
- `helmfile/mongodb/passwords.yaml.gotmpl`

**Steps:**
```bash
# Generate strong passwords if not in 1Password
ROOT_PASSWORD=$(openssl rand -base64 32)
REPLICA_KEY=$(openssl rand -base64 756)

# Or extract from 1Password
# ROOT_PASSWORD=$(op read "op://Private/mongodb-root/password")

# Create secret
cat > /tmp/mongodb-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secrets
  namespace: mongodb
type: Opaque
stringData:
  mongodb-root-password: "$ROOT_PASSWORD"
  mongodb-replica-set-key: "$REPLICA_KEY"
EOF

# Seal it
kubeseal --format=yaml --cert=pub-sealed-secrets.pem \
  < /tmp/mongodb-secret.yaml > helmfile/mongodb/sealed-secret.yaml

# Update helmfile
rm /tmp/mongodb-secret.yaml
git add helmfile/mongodb/sealed-secret.yaml
```

---

### RabbitMQ

**Secrets Needed:**
- Admin password
- Erlang cookie

**Files to Check:**
- `helmfile/rabbitmq/helmfile.yaml`

**Steps:**
```bash
# Generate or extract passwords
RABBITMQ_PASSWORD=$(openssl rand -base64 32)
ERLANG_COOKIE=$(openssl rand -base64 32)

# Create secret
cat > /tmp/rabbitmq-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: rabbitmq-secrets
  namespace: rabbitmq
type: Opaque
stringData:
  rabbitmq-password: "$RABBITMQ_PASSWORD"
  rabbitmq-erlang-cookie: "$ERLANG_COOKIE"
EOF

# Seal it
kubeseal --format=yaml --cert=pub-sealed-secrets.pem \
  < /tmp/rabbitmq-secret.yaml > helmfile/rabbitmq/sealed-secret.yaml

# Update helmfile
rm /tmp/rabbitmq-secret.yaml
git add helmfile/rabbitmq/sealed-secret.yaml
```

---

## Validation Steps

### 1. Verify Sealed Secret Format
```bash
# Should see SealedSecret kind
cat helmfile/grafana/sealed-secret.yaml | head -5
```

Expected output:
```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: grafana-secrets
  namespace: grafana
```

### 2. Test Unsealing (Optional)
```bash
# Apply sealed secret to cluster
kubectl apply -f helmfile/grafana/sealed-secret.yaml

# Check if unsealed secret was created
kubectl get secret -n grafana grafana-secrets

# View secret (base64 encoded)
kubectl get secret -n grafana grafana-secrets -o yaml

# Clean up test
kubectl delete -f helmfile/grafana/sealed-secret.yaml
```

### 3. Verify No Plain Secrets in Git
```bash
# This should return nothing
git grep -i "password.*:" helmfile/ | grep -v "passwordSecretRef" | grep -v "# password"
```

---

## Troubleshooting

### Error: cannot fetch certificate
```bash
# Ensure sealed-secrets controller is running
kubectl get pods -n kube-system -l name=sealed-secrets-controller

# Re-fetch certificate
kubeseal --fetch-cert --controller-name=sealed-secrets-controller \
  --controller-namespace=kube-system > pub-sealed-secrets.pem
```

### Error: cannot seal secret
```bash
# Verify certificate exists
cat pub-sealed-secrets.pem

# Check kubeseal version
kubeseal --version

# Try with explicit controller
kubeseal --format=yaml \
  --controller-name=sealed-secrets-controller \
  --controller-namespace=kube-system \
  < secret.yaml > sealed-secret.yaml
```

### Secret not unsealing in cluster
```bash
# Check sealed-secrets controller logs
kubectl logs -n kube-system -l name=sealed-secrets-controller

# Common issues:
# - Wrong namespace in sealed secret
# - Controller restarted and lost private key (restore from backup)
# - Sealed with wrong certificate
```

---

## Completion Checklist

- [ ] All `op://` references identified
- [ ] Grafana sealed secret created
- [ ] OAuth2-proxy sealed secret created
- [ ] Cert-manager sealed secret created
- [ ] MongoDB sealed secret created (if needed)
- [ ] RabbitMQ sealed secret created (if needed)
- [ ] Kafka sealed secret created (if needed)
- [ ] All helmfiles updated to use sealed secrets
- [ ] All temporary secret files deleted
- [ ] All sealed secrets committed to Git
- [ ] No plain secrets in Git repository
- [ ] Validation tests passed
- [ ] Documentation updated

---

## After Completion

When all secrets are converted:
1. ✅ Phase 5 complete
2. 🚀 Proceed to Phase 6 - Deploy root application
3. 📋 Follow deployment order in ARCHITECTURE.md

---

## Quick Command Reference

```bash
# Seal a secret
kubeseal --format=yaml --cert=pub-sealed-secrets.pem < secret.yaml > sealed.yaml

# Extract from 1Password
op read "op://Private/item-name/field-name"

# Generate random password
openssl rand -base64 32

# Test sealed secret
kubectl apply -f sealed-secret.yaml
kubectl get secret -n <namespace> <name>
kubectl delete -f sealed-secret.yaml

# Search for secrets
grep -r "op://" helmfile/
```

