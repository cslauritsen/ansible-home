# Kubernetes Dashboard - Migration from Helmfile to ArgoCD with OAuth2-Proxy

## Overview

This migration moves the kubernetes-dashboard from helmfile (with chartlify extras) to ArgoCD with OAuth2-proxy authentication, eliminating the need for:
- Manual token-based authentication
- The `extras/` directory with custom ingress, service account, and RBAC manifests
- Direct cluster-admin service account tokens

## What Changed

### Before (Helmfile)
- Used helmfile with two releases:
  1. `kubernetes-dashboard` - main chart
  2. `kubernetes-dashboard-extras` - chartlify'd custom resources (ingress, SA, RBAC)
- Required manual token extraction for authentication
- Direct ingress without authentication layer

### After (ArgoCD + OAuth2-Proxy)
- Single ArgoCD Application with multiple sources:
  1. Upstream kubernetes-dashboard Helm chart (with values)
  2. Git repo extras for additional RBAC
- OAuth2-proxy handles authentication
- Users authenticated via Google OAuth (or your configured provider)
- Automatic admin access for whitelisted users

## Architecture

```
User → nginx-ingress (with oauth2-proxy auth) → OAuth2-Proxy → Dashboard
                                                       ↓
                                                 Google OAuth
```

1. User navigates to `https://kubernetes-dashboard.home.planetlauritsen.com`
2. nginx-ingress checks authentication via oauth2-proxy
3. If not authenticated, redirects to oauth2-proxy
4. oauth2-proxy authenticates via Google OAuth
5. Only emails in `/helmfile/oauth2-proxy/rsrc/allowed-emails.yaml` are allowed
6. After authentication, user is redirected back to dashboard
7. Dashboard service account has cluster-admin permissions

## Files

### New Files
- `/argocd/applications/kubernetes-dashboard.yaml` - ArgoCD Application manifest
- `/helmfile/kubernetes-dashboard/argocd-extras/rbac.yaml` - RBAC configuration

### Deprecated Files (Can be Removed)
- `/helmfile/kubernetes-dashboard/extras/ingress.yaml` - Replaced by inline values in ArgoCD app
- `/helmfile/kubernetes-dashboard/extras/sa.yaml` - Handled by Helm chart + extras RBAC
- `/helmfile/kubernetes-dashboard/extras/roles.yaml` - Replaced by extras RBAC
- `/helmfile/kubernetes-dashboard/helmfile.yaml` - No longer needed
- `/argocd/applications-disabled/kubernetes-dashboard.yaml` - Replaced by new version

## Prerequisites

1. **OAuth2-Proxy must be deployed and configured**
   - Check: `kubectl get pods -n oauth2-proxy`
   - ArgoCD app: `/argocd/applications-disabled/oauth2-proxy.yaml`
   - Enable if needed: Move from `applications-disabled/` to `applications/`

2. **Your email must be in the allowlist**
   - File: `/helmfile/oauth2-proxy/rsrc/allowed-emails.yaml`
   - Check current emails: `kubectl get configmap allowed-emails -n oauth2-proxy -o yaml`

3. **cert-manager must be deployed**
   - For automatic TLS certificates
   - Check: `kubectl get pods -n cert-manager`

4. **nginx-ingress must be deployed**
   - With external-auth support
   - Check: `kubectl get pods -n ingress-nginx`

## Deployment Steps

### Step 1: Ensure OAuth2-Proxy is Running

If not already deployed:

```bash
# Move oauth2-proxy to active applications
cd /Users/csl04r/repos/cslauritsen/ansible-home/argocd
git mv applications-disabled/oauth2-proxy.yaml applications/

# Commit and push
git add .
git commit -m "Enable oauth2-proxy for kubernetes-dashboard"
git push

# Wait for ArgoCD to sync (or manually sync in UI)
kubectl get pods -n oauth2-proxy -w
```

### Step 2: Verify Your Email is Whitelisted

```bash
# Check allowed emails
kubectl get configmap allowed-emails -n oauth2-proxy -o jsonpath='{.data.allowed-emails\.txt}'

# If your email is not listed, add it:
# Edit: /helmfile/oauth2-proxy/rsrc/allowed-emails.yaml
# Commit, push, and let ArgoCD sync
```

### Step 3: Deploy Kubernetes Dashboard via ArgoCD

The new application manifest is already in place at:
`/argocd/applications/kubernetes-dashboard.yaml`

```bash
# If using app-of-apps pattern, ArgoCD will auto-detect and deploy
# Otherwise, manually apply:
kubectl apply -f /Users/csl04r/repos/cslauritsen/ansible-home/argocd/applications/kubernetes-dashboard.yaml

# Watch the deployment
kubectl get application kubernetes-dashboard -n argocd -w
kubectl get pods -n kubernetes-dashboard -w
```

### Step 4: Remove Old Helmfile Deployment (if exists)

```bash
# If the old helmfile deployment exists, remove it
helmfile -f /Users/csl04r/repos/cslauritsen/ansible-home/helmfile/kubernetes-dashboard/helmfile.yaml destroy

# Or manually delete resources
kubectl delete namespace kubernetes-dashboard
# Then proceed with ArgoCD deployment
```

### Step 5: Test Access

1. Navigate to: `https://kubernetes-dashboard.home.planetlauritsen.com`
2. You should be redirected to OAuth2-proxy
3. Authenticate with your Google account
4. You should automatically land in the dashboard with admin access
5. No token input should be required!

## Verification

### Check ArgoCD Application Status
```bash
kubectl get application kubernetes-dashboard -n argocd
argocd app get kubernetes-dashboard
```

### Check Dashboard Pods
```bash
kubectl get pods -n kubernetes-dashboard
kubectl logs -n kubernetes-dashboard -l app.kubernetes.io/name=kubernetes-dashboard
```

### Check Ingress
```bash
kubectl get ingress -n kubernetes-dashboard
kubectl describe ingress -n kubernetes-dashboard
```

### Check RBAC
```bash
kubectl get clusterrolebinding oauth2-dashboard-admin
kubectl describe clusterrolebinding oauth2-dashboard-admin
```

### Test Authentication Flow
```bash
# Check oauth2-proxy logs during login
kubectl logs -n oauth2-proxy -l app.kubernetes.io/name=oauth2-proxy -f

# Check nginx-ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f | grep kubernetes-dashboard
```

## Troubleshooting

### Issue: Redirected to OAuth2-Proxy but Get 403 Forbidden

**Cause:** Your email is not in the allowlist

**Solution:**
```bash
# Add your email to /helmfile/oauth2-proxy/rsrc/allowed-emails.yaml
# Commit and push
# Wait for ArgoCD to sync oauth2-proxy
```

### Issue: Dashboard Shows "Forbidden" or Limited Access

**Cause:** RBAC not properly configured

**Solution:**
```bash
# Check if ClusterRoleBinding exists
kubectl get clusterrolebinding oauth2-dashboard-admin

# If missing, manually apply:
kubectl apply -f /Users/csl04r/repos/cslauritsen/ansible-home/helmfile/kubernetes-dashboard/argocd-extras/rbac.yaml

# Or sync the ArgoCD app
argocd app sync kubernetes-dashboard
```

### Issue: SSL/TLS Certificate Not Working

**Cause:** cert-manager not creating certificate

**Solution:**
```bash
# Check certificate
kubectl get certificate -n kubernetes-dashboard
kubectl describe certificate kubernetes-dashboard-tls -n kubernetes-dashboard

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f

# Manual certificate request
kubectl get certificaterequest -n kubernetes-dashboard
```

### Issue: Backend Protocol Error

**Cause:** Dashboard service uses HTTPS but nginx can't verify cert

**Solution:** This is already configured with:
```yaml
nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
```

If issues persist:
```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller | grep kubernetes-dashboard
```

## Configuration Customization

### Change Dashboard Version

Edit `/argocd/applications/kubernetes-dashboard.yaml`:
```yaml
targetRevision: 7.10.0  # Change this version
```

### Change Hostname

Edit `/argocd/applications/kubernetes-dashboard.yaml`:
```yaml
hosts:
  - kubernetes-dashboard.YOURDOMAIN.com
tls:
  - secretName: kubernetes-dashboard-tls
    hosts:
      - kubernetes-dashboard.YOURDOMAIN.com
```

Also update OAuth2-proxy annotations:
```yaml
nginx.ingress.kubernetes.io/auth-signin: https://oauth2-proxy.YOURDOMAIN.com/oauth2/start?rd=https://$host$request_uri
nginx.ingress.kubernetes.io/auth-url: https://oauth2-proxy.YOURDOMAIN.com/oauth2/auth
```

### Restrict Access to Specific Users (Beyond OAuth2-Proxy)

For more granular RBAC within the dashboard, you can create additional RoleBindings:

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dashboard-viewer-specific-ns
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
  - kind: User
    name: user@example.com  # Email from OAuth2
    apiGroup: rbac.authorization.k8s.io
```

However, with the current setup, all OAuth2-authenticated users get cluster-admin, which is appropriate for a home lab with a small trusted user list.

## Security Notes

1. **OAuth2-Proxy Whitelist**: Only emails in `/helmfile/oauth2-proxy/rsrc/allowed-emails.yaml` can access the dashboard
2. **Cluster-Admin**: All whitelisted users get full cluster-admin access
3. **TLS**: All traffic is encrypted via Let's Encrypt certificates
4. **Cookie Security**: OAuth2-proxy uses secure, http-only cookies
5. **No Token Exposure**: No need to extract or share service account tokens

## Cleanup Old Files (Optional)

After successful deployment and verification:

```bash
cd /Users/csl04r/repos/cslauritsen/ansible-home

# Remove old extras directory
rm -rf helmfile/kubernetes-dashboard/extras/

# Remove old helmfile.yaml
rm helmfile/kubernetes-dashboard/helmfile.yaml

# Remove old disabled ArgoCD app
rm argocd/applications-disabled/kubernetes-dashboard.yaml

# Commit changes
git add .
git commit -m "Clean up old kubernetes-dashboard helmfile artifacts"
git push
```

## References

- [Kubernetes Dashboard Helm Chart](https://github.com/kubernetes/dashboard/tree/master/charts/helm-chart/kubernetes-dashboard)
- [OAuth2-Proxy Documentation](https://oauth2-proxy.github.io/oauth2-proxy/)
- [nginx-ingress External Auth](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#external-authentication)
- [ArgoCD Multiple Sources](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)

## Support

For issues or questions:
1. Check ArgoCD UI: `https://argocd.home.planetlauritsen.com`
2. Check application logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server`
3. Review this guide's Troubleshooting section

