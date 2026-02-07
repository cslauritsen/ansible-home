# ArgoCD Implementation Plan - Detailed Checklist

Deploy ArgoCD on your K3s cluster to enable GitOps-based deployment management, allowing you to update applications by committing to a GitHub repository. This checklist provides step-by-step tasks to complete the implementation.

## Implementation Checklist

### Phase 1: Secret Management Setup (Sealed Secrets)

#### 1.1 Install kubeseal CLI
- [x] Install kubeseal: `brew install kubeseal`
- [x] Verify installation: `kubeseal --version`

#### 1.2 Deploy Sealed Secrets Controller
- [x] Create helmfile directory: `mkdir -p helmfile/sealed-secrets`
- [x] Create `helmfile/sealed-secrets/helmfile.yaml` with sealed-secrets chart
- [x] Deploy controller: `helmfile -f helmfile/sealed-secrets/helmfile.yaml apply`
- [x] Verify controller is running: `kubectl get pods -n kube-system -l name=sealed-secrets-controller`

#### 1.3 Backup and Store Public Key
- [x] Fetch public certificate: `kubeseal --fetch-cert --controller-name=sealed-secrets-controller --controller-namespace=kube-system > pub-sealed-secrets.pem`
- [x] Commit public cert to repo: `git add pub-sealed-secrets.pem && git commit -m "Add sealed secrets public key"`
- [x] Backup private key: `kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-key.backup.yaml`
- [x] Store backup securely (in 1Password or encrypted storage)

#### 1.4 Test Sealed Secrets
- [x] Create test secret: `echo -n "test-value" | kubectl create secret generic test-secret --dry-run=client --from-file=password=/dev/stdin -o yaml | kubeseal -o yaml > test-sealed-secret.yaml`
- [x] Apply sealed secret: `kubectl apply -f test-sealed-secret.yaml`
- [x] Verify unsealing: `kubectl get secret test-secret -o yaml`
- [x] Clean up test: `kubectl delete secret test-secret && rm test-sealed-secret.yaml`

---

### Phase 2: ArgoCD Deployment

#### 2.1 Create ArgoCD Helmfile Configuration
- [x] Create directory: `mkdir -p helmfile/argocd`
- [x] Create `helmfile/argocd/helmfile.yaml` with ArgoCD helm chart reference
- [x] Add repository: `https://argoproj.github.io/argo-helm`
- [x] Set namespace to `argocd` with `createNamespace: true`
- [x] Set kubeContext to `rpi`

#### 2.2 Create ArgoCD Values File
- [x] Create `helmfile/argocd/values.yaml`
- [x] Configure server ingress settings:
  - [x] Enable ingress
  - [x] Set host (e.g., `argocd.home.planetlauritsen.com`)
  - [x] Add cert-manager annotations for TLS
  - [x] Set ingressClassName to `nginx`
- [x] Configure ARM64 compatibility (if needed)
- [x] Disable dex (using oauth2-proxy instead) or configure GitHub SSO
- [x] Set initial admin password or use random generation

#### 2.3 Create Ingress and TLS Resources
- [x] Create `helmfile/argocd/extras/` directory
- [x] Create certificate resource for ArgoCD domain (or use wildcard cert)
- [x] Optional: Create oauth2-proxy configuration if using external auth

#### 2.4 Deploy ArgoCD
- [x] Deploy: `helmfile -f helmfile/argocd/helmfile.yaml apply`
- [x] Wait for pods: `kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s`
- [x] Get admin password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
- [x] Save admin password securely (may not need it if oauth2-proxy RBAC is configured)

#### 2.5 Access ArgoCD UI
- [x] Access via ingress: `https://argocd.home.planetlauritsen.com`
- [x] Or port-forward: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
- [x] Login with admin credentials OR use oauth2-proxy authentication (see 2.6)
- [x] Verify UI loads successfully

#### 2.6 Configure OAuth2-Proxy RBAC (Optional but Recommended)
- [x] Configuration added to grant admin privileges to oauth2-proxy authenticated users
- [ ] Review `helmfile/argocd/README-OAUTH2-RBAC.md` for details
- [ ] Decide on approach: grant admin to all oauth2-proxy users OR set up granular OIDC
- [ ] If using approach 1 (grant admin to all): ensure oauth2-proxy's allowed-emails.txt is properly restricted
- [ ] Apply updated configuration: `helmfile -f helmfile/argocd/helmfile.yaml apply`
- [ ] Test: Access ArgoCD and verify you have admin privileges without logging in again

---

### Phase 3: GitHub Repository Configuration

#### 3.1 Prepare GitHub Repository
- [ ] Ensure ansible-home repo is pushed to GitHub
- [ ] Create GitHub Personal Access Token (PAT) with `repo` scope
- [ ] Or generate SSH deploy key: `ssh-keygen -t ed25519 -C "argocd@rpi-cluster" -f ~/.ssh/argocd-deploy-key`

#### 3.2 Create Repository Secret in ArgoCD
- [ ] Option A - Via UI: Add repository in ArgoCD Settings → Repositories
- [ ] Option B - Via sealed secret:
  - [ ] Create secret YAML with GitHub credentials
  - [ ] Seal it: `kubeseal < github-repo-secret.yaml -o yaml > sealed-github-repo-secret.yaml`
  - [ ] Apply: `kubectl apply -f sealed-github-repo-secret.yaml`
- [ ] Test connection in ArgoCD UI

---

### Phase 4: Create ArgoCD Applications

#### 4.1 Create Applications Directory Structure
- [ ] Create: `mkdir -p helmfile/argocd/applications`
- [ ] Create: `mkdir -p helmfile/argocd/app-of-apps`

#### 4.2 Create App-of-Apps Pattern
- [ ] Create `helmfile/argocd/app-of-apps/root-app.yaml` (ArgoCD Application that manages other Applications)
- [ ] Configure to watch `helmfile/argocd/applications/` directory
- [ ] Set sync policy to manual initially
- [ ] Set destination to `rpi` cluster

#### 4.3 Create Individual Application Manifests
- [ ] Create `helmfile/argocd/applications/metallb.yaml`
- [ ] Create `helmfile/argocd/applications/cert-manager.yaml`
- [ ] Create `helmfile/argocd/applications/ingress-nginx.yaml`
- [ ] Create `helmfile/argocd/applications/longhorn.yaml`
- [ ] Add more applications as needed

#### 4.4 Configure Application Sources
- [ ] Set `repoURL` to your GitHub repository
- [ ] Set `targetRevision` to `main` or `HEAD`
- [ ] Set `path` to helmfile directory (e.g., `helmfile/metallb`)
- [ ] Configure sync policy (manual vs automatic)
- [ ] Add sync options (e.g., `CreateNamespace=true`)

---

### Phase 5: Convert Secrets to Sealed Secrets

#### 5.1 Identify Current Secrets Using `op` CLI
- [ ] Review `helmfile/grafana/helmfile.yaml` - Grafana Cloud credentials
- [ ] Review `helmfile/oauth2-proxy/helmfile.yaml` - OAuth2 client secrets
- [ ] Review `helmfile/cert-manager/rsrc/secret.yaml.gotmpl` - Cloudflare API token
- [ ] List all other secrets using `op` exec

#### 5.2 Convert Grafana Secrets
- [ ] Extract secrets from 1Password: `op read "op://Private/n4b33z3lps73pnkdmyawdxfdoq/password"`
- [ ] Create Kubernetes Secret YAML
- [ ] Seal it: `kubeseal < grafana-secret.yaml -o yaml > helmfile/grafana/sealed-secret.yaml`
- [ ] Update `helmfile/grafana/helmfile.yaml` to reference sealed secret
- [ ] Commit sealed secret to Git

#### 5.3 Convert OAuth2-Proxy Secrets
- [ ] Extract client ID, secret, and cookie secret from 1Password
- [ ] Create Secret YAML with all values
- [ ] Seal it: `kubeseal < oauth2-secret.yaml -o yaml > helmfile/oauth2-proxy/sealed-secret.yaml`
- [ ] Update helmfile to use existing secret instead of inline values
- [ ] Commit to Git

#### 5.4 Convert Cert-Manager Secrets
- [ ] Extract Cloudflare API token from 1Password
- [ ] Create Secret YAML
- [ ] Seal it: `kubeseal < cloudflare-secret.yaml -o yaml > helmfile/cert-manager/rsrc/sealed-cloudflare-secret.yaml`
- [ ] Remove `.gotmpl` file and update helmfile
- [ ] Commit to Git

#### 5.5 Convert Remaining Secrets
- [ ] Identify other secrets (postgres, mongodb, rabbitmq, etc.)
- [ ] Convert each using the same pattern
- [ ] Test each application after conversion

---

### Phase 6: Deploy Root Application and Test

#### 6.1 Deploy App-of-Apps
- [ ] Apply root application: `kubectl apply -f helmfile/argocd/app-of-apps/root-app.yaml`
- [ ] Verify in ArgoCD UI that root app appears
- [ ] Check that child applications are created automatically

#### 6.2 Sync First Application
- [ ] Choose a simple app to test (e.g., metallb)
- [ ] Click "Sync" in ArgoCD UI
- [ ] Review differences before syncing
- [ ] Confirm sync
- [ ] Verify application is healthy and synced

#### 6.3 Test Secret Management
- [ ] Sync an application with sealed secrets (e.g., cert-manager)
- [ ] Verify sealed secret is created
- [ ] Verify unsealed secret is created automatically
- [ ] Check application pods can access the secret

#### 6.4 Gradually Sync Remaining Apps
- [ ] Sync cert-manager
- [ ] Sync ingress-nginx
- [ ] Sync oauth2-proxy
- [ ] Sync remaining applications one by one
- [ ] Verify each is healthy before moving to next

---

### Phase 7: Enable GitOps Workflow

#### 7.1 Test Git-Based Updates
- [ ] Make a small change to a helmfile (e.g., update a label)
- [ ] Commit and push to GitHub
- [ ] Wait or manually refresh in ArgoCD
- [ ] Verify ArgoCD detects the change (shows "OutOfSync")
- [ ] Click sync to apply the change

#### 7.2 Enable Auto-Sync (Optional)
- [ ] Update Application manifests with `automated: {}` in syncPolicy
- [ ] Or enable via UI: App Settings → Sync Policy → Enable Auto-Sync
- [ ] Enable self-heal and prune options if desired
- [ ] Test automatic sync by making another change

#### 7.3 Configure Notifications (Optional)
- [ ] Install ArgoCD notifications controller
- [ ] Configure Slack/Discord/Email notifications
- [ ] Test notifications on sync success/failure

---

### Phase 8: Cleanup and Documentation

#### 8.1 Remove Manual Deployment Dependencies
- [ ] Document that helmfile apply commands are no longer needed
- [ ] Remove any CI/CD jobs running helmfile directly
- [ ] Update README with new ArgoCD workflow

#### 8.2 Backup ArgoCD Configuration
- [ ] Export ArgoCD applications: `kubectl get applications -n argocd -o yaml > argocd-apps-backup.yaml`
- [ ] Store backup securely
- [ ] Document recovery procedures

#### 8.3 Update Documentation
- [ ] Create `README-ARGOCD.md` with:
  - [ ] How to access ArgoCD UI
  - [ ] How to create new applications
  - [ ] How to seal secrets
  - [ ] How to sync applications manually
  - [ ] Troubleshooting common issues

---

## Quick Reference Commands

### Sealed Secrets
```bash
# Seal a secret
kubeseal < secret.yaml -o yaml > sealed-secret.yaml

# Fetch public cert
kubeseal --fetch-cert > pub-sealed-secrets.pem

# Backup private key
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > backup.yaml
```

### ArgoCD
```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login with CLI
argocd login localhost:8080

# Sync an application
argocd app sync <app-name>

# Get app status
argocd app get <app-name>
```

### Helmfile
```bash
# Deploy a helmfile
helmfile -f helmfile/argocd/helmfile.yaml apply

# List releases
helmfile -f helmfile/argocd/helmfile.yaml list

# Diff before apply
helmfile -f helmfile/argocd/helmfile.yaml diff
```

---

## Progress Tracking

- **Phase 1**: ☐ Secret Management Setup
- **Phase 2**: ☐ ArgoCD Deployment  
- **Phase 3**: ☐ GitHub Repository Configuration
- **Phase 4**: ☐ Create ArgoCD Applications
- **Phase 5**: ☐ Convert Secrets to Sealed Secrets
- **Phase 6**: ☐ Deploy Root Application and Test
- **Phase 7**: ☐ Enable GitOps Workflow
- **Phase 8**: ☐ Cleanup and Documentation

**Current Phase**: Phase 1 - Secret Management Setup

---

## Decision Points & Recommendations

### Secret Management
- **Decision**: Use Sealed Secrets (free, no external dependencies)
- **Rationale**: Eliminates laptop dependency, GitOps-native, no additional costs
- **Alternative**: External Secrets Operator if you need cloud integration later

### Sync Strategy
- **Decision**: Start with manual sync
- **Rationale**: Safer during initial setup, can enable auto-sync per-app later
- **When to auto-sync**: After validating each application works correctly

### Authentication
- **Decision**: Use oauth2-proxy (consistent with existing setup)
- **Rationale**: Already configured for Longhorn, reuse same pattern
- **Alternative**: ArgoCD built-in GitHub SSO for simpler setup

### Repository Structure
- **Decision**: Use existing ansible-home repo
- **Rationale**: Simpler to start, can refactor later if needed
- **When to separate**: If you want different access controls or multiple teams

---

## Notes Section

**Started**: _______________

**Completed**: _______________

**Issues Encountered**:
- 
- 
- 

**Custom Modifications**:
- 
- 
-

