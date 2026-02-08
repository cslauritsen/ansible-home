# Kubernetes Dashboard Deployment Checklist

## Pre-Deployment Checklist

### ☐ 1. Verify Prerequisites Are Deployed

#### OAuth2-Proxy (CRITICAL - Required for authentication)
```bash
# Check if oauth2-proxy is deployed
kubectl get pods -n oauth2-proxy

# If NOT deployed, enable it:
cd /Users/csl04r/repos/cslauritsen/ansible-home/argocd
git mv applications-disabled/oauth2-proxy.yaml applications/
git add .
git commit -m "Enable oauth2-proxy for kubernetes-dashboard authentication"
git push

# Wait for ArgoCD to sync (or manually sync)
argocd app sync oauth2-proxy
kubectl get pods -n oauth2-proxy -w
```

#### Nginx Ingress Controller (CRITICAL - Required for routing)
```bash
# Check if nginx-ingress is deployed
kubectl get pods -n ingress-nginx

# If NOT deployed, enable it:
cd /Users/csl04r/repos/cslauritsen/ansible-home/argocd
git mv applications-disabled/ingress-nginx.yaml applications/
git add .
git commit -m "Enable ingress-nginx"
git push
```

#### Cert-Manager (CRITICAL - Required for TLS certificates)
```bash
# Check if cert-manager is deployed
kubectl get pods -n cert-manager

# If NOT deployed, enable it:
cd /Users/csl04r/repos/cslauritsen/ansible-home/argocd
git mv applications-disabled/cert-manager.yaml applications/
git add .
git commit -m "Enable cert-manager for TLS certificates"
git push
```

#### Sealed Secrets (Optional - Only if using sealed secrets)
```bash
# Check if sealed-secrets is deployed
kubectl get pods -n kube-system | grep sealed-secrets

# If NOT deployed and you need it:
cd /Users/csl04r/repos/cslauritsen/ansible-home/argocd
git mv applications-disabled/sealed-secrets.yaml applications/
git add .
git commit -m "Enable sealed-secrets"
git push
```

### ☐ 2. Verify Your Email Is Whitelisted

```bash
# Check current whitelist
kubectl get configmap allowed-emails -n oauth2-proxy -o jsonpath='{.data.allowed-emails\.txt}'

# Or check the file directly
cat /Users/csl04r/repos/cslauritsen/ansible-home/helmfile/oauth2-proxy/rsrc/allowed-emails.yaml
```

**If your email is NOT listed:**
```bash
# Edit the file
vim /Users/csl04r/repos/cslauritsen/ansible-home/helmfile/oauth2-proxy/rsrc/allowed-emails.yaml

# Add your email to the list (one per line)
# Example:
# allowed-emails.txt: |-
#   csl4jc@gmail.com
#   youremail@gmail.com

# Commit and push
git add helmfile/oauth2-proxy/rsrc/allowed-emails.yaml
git commit -m "Add youremail@gmail.com to oauth2-proxy whitelist"
git push

# Sync oauth2-proxy to apply changes
argocd app sync oauth2-proxy
```

### ☐ 3. Verify OAuth2-Proxy Configuration

```bash
# Check oauth2-proxy secrets exist
kubectl get secret oauth2-proxy-secrets -n oauth2-proxy

# Check oauth2-proxy service is running
kubectl get svc -n oauth2-proxy

# Check oauth2-proxy ingress
kubectl get ingress -n oauth2-proxy

# Test oauth2-proxy endpoint
curl -I https://oauth2-proxy.home.planetlauritsen.com/ping
# Should return: 200 OK
```

### ☐ 4. Remove Old Helmfile Deployment (If Exists)

```bash
# Check if old deployment exists
kubectl get namespace kubernetes-dashboard

# If it exists and was deployed via helmfile:
cd /Users/csl04r/repos/cslauritsen/ansible-home
helmfile -f helmfile/kubernetes-dashboard/helmfile.yaml destroy

# Or manually delete the namespace
kubectl delete namespace kubernetes-dashboard

# Wait for namespace to be fully deleted
kubectl get namespace kubernetes-dashboard -w
# (Press Ctrl+C when it's gone)
```

## Deployment Steps

### ☐ 5. Commit and Push All New Files

```bash
cd /Users/csl04r/repos/cslauritsen/ansible-home

# Check what's new
git status

# Add all new files
git add argocd/applications/kubernetes-dashboard.yaml
git add helmfile/kubernetes-dashboard/argocd-extras/
git add helmfile/kubernetes-dashboard/*.md

# Commit
git commit -m "Migrate kubernetes-dashboard to ArgoCD with OAuth2-proxy authentication"

# Push
git push
```

### ☐ 6. Deploy via ArgoCD

**Option A: Using app-of-apps (Automatic)**

If you're using the root-app pattern, ArgoCD will automatically detect the new application:

```bash
# Sync the root app to pick up new application
argocd app sync root-app

# Watch for kubernetes-dashboard app to appear
argocd app list | grep kubernetes-dashboard

# Sync the kubernetes-dashboard app
argocd app sync kubernetes-dashboard
```

**Option B: Manual Application**

```bash
# Apply the application manifest
kubectl apply -f /Users/csl04r/repos/cslauritsen/ansible-home/argocd/applications/kubernetes-dashboard.yaml

# Watch the application status
kubectl get application kubernetes-dashboard -n argocd -w

# Sync the application
argocd app sync kubernetes-dashboard
```

### ☐ 7. Watch Deployment Progress

```bash
# Watch ArgoCD application
kubectl get application kubernetes-dashboard -n argocd -w

# Watch pods being created
kubectl get pods -n kubernetes-dashboard -w

# Check application details
argocd app get kubernetes-dashboard
```

## Post-Deployment Verification

### ☐ 8. Verify All Resources Are Created

```bash
# Check namespace
kubectl get namespace kubernetes-dashboard

# Check pods (should be Running)
kubectl get pods -n kubernetes-dashboard

# Check services
kubectl get svc -n kubernetes-dashboard

# Check ingress (should have ADDRESS assigned)
kubectl get ingress -n kubernetes-dashboard

# Check RBAC
kubectl get clusterrolebinding oauth2-dashboard-admin

# Check certificate (should be Ready)
kubectl get certificate -n kubernetes-dashboard
```

### ☐ 9. Verify RBAC Permissions

```bash
# Check ClusterRoleBinding exists
kubectl get clusterrolebinding oauth2-dashboard-admin

# Verify it's bound to cluster-admin role
kubectl describe clusterrolebinding oauth2-dashboard-admin

# Test dashboard service account permissions
kubectl auth can-i --list --as=system:serviceaccount:kubernetes-dashboard:kubernetes-dashboard | head -20
```

### ☐ 10. Verify TLS Certificate

```bash
# Check certificate resource
kubectl get certificate kubernetes-dashboard-tls -n kubernetes-dashboard

# Should show: READY = True
# If not ready, check details:
kubectl describe certificate kubernetes-dashboard-tls -n kubernetes-dashboard

# Check certificate request
kubectl get certificaterequest -n kubernetes-dashboard

# Check cert-manager logs if issues
kubectl logs -n cert-manager -l app=cert-manager | tail -50
```

### ☐ 11. Verify Ingress Configuration

```bash
# Check ingress details
kubectl describe ingress -n kubernetes-dashboard

# Should see annotations:
# - cert-manager.io/cluster-issuer: letsencrypt-dns
# - nginx.ingress.kubernetes.io/auth-signin
# - nginx.ingress.kubernetes.io/auth-url
# - nginx.ingress.kubernetes.io/backend-protocol: HTTPS

# Check ingress has ADDRESS assigned
kubectl get ingress -n kubernetes-dashboard
```

### ☐ 12. Test Access

```bash
# DNS resolution
nslookup kubernetes-dashboard.home.planetlauritsen.com

# TLS handshake
curl -I https://kubernetes-dashboard.home.planetlauritsen.com
# Should get redirect to oauth2-proxy

# Full test - open in browser
open https://kubernetes-dashboard.home.planetlauritsen.com
```

**Expected Flow:**
1. Browser opens dashboard URL
2. Redirect to oauth2-proxy
3. Redirect to Google OAuth login
4. Authenticate with whitelisted email
5. Redirect back to dashboard
6. Dashboard opens with full admin access (no token required!)

## Troubleshooting

### Issue: OAuth2-Proxy Not Found

**Symptoms:** 
```bash
kubectl get pods -n oauth2-proxy
# No resources found
```

**Fix:** Deploy oauth2-proxy (see step 1)

### Issue: 403 Forbidden After OAuth Login

**Symptoms:** OAuth login succeeds but dashboard shows 403

**Cause:** Email not whitelisted

**Fix:**
```bash
# Check whitelist
kubectl get configmap allowed-emails -n oauth2-proxy -o yaml

# Add your email (see step 2)
```

### Issue: Certificate Not Ready

**Symptoms:**
```bash
kubectl get certificate -n kubernetes-dashboard
# Shows READY = False
```

**Fix:**
```bash
# Check certificate details
kubectl describe certificate kubernetes-dashboard-tls -n kubernetes-dashboard

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f

# Check ClusterIssuer
kubectl get clusterissuer letsencrypt-dns
kubectl describe clusterissuer letsencrypt-dns

# If needed, delete and recreate certificate
kubectl delete certificate kubernetes-dashboard-tls -n kubernetes-dashboard
# ArgoCD will recreate it
```

### Issue: Ingress No ADDRESS

**Symptoms:**
```bash
kubectl get ingress -n kubernetes-dashboard
# ADDRESS column is empty
```

**Fix:**
```bash
# Check nginx-ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller | tail -50

# Check LoadBalancer service
kubectl get svc -n ingress-nginx

# May need to deploy metallb for LoadBalancer support
```

### Issue: Dashboard Shows Limited Permissions

**Symptoms:** Dashboard loads but can't see/create resources

**Fix:**
```bash
# Check ClusterRoleBinding
kubectl get clusterrolebinding oauth2-dashboard-admin

# If missing, apply RBAC
kubectl apply -f /Users/csl04r/repos/cslauritsen/ansible-home/helmfile/kubernetes-dashboard/argocd-extras/rbac.yaml

# Or force ArgoCD sync
argocd app sync kubernetes-dashboard --force
```

### Issue: Backend Protocol Error

**Symptoms:** nginx logs show SSL errors connecting to dashboard backend

**Check nginx logs:**
```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller | grep kubernetes-dashboard
```

**Fix:** Should already be configured with `nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"`

If issue persists:
```bash
# Check dashboard service
kubectl get svc -n kubernetes-dashboard
kubectl describe svc -n kubernetes-dashboard

# Check dashboard pods
kubectl logs -n kubernetes-dashboard -l app.kubernetes.io/name=kubernetes-dashboard
```

## Success Criteria

✅ All checks passing:

- [ ] OAuth2-proxy pods running
- [ ] Nginx-ingress pods running  
- [ ] Cert-manager pods running
- [ ] Your email in oauth2-proxy whitelist
- [ ] Old helmfile deployment removed
- [ ] New ArgoCD application synced
- [ ] kubernetes-dashboard pods running
- [ ] Ingress has ADDRESS assigned
- [ ] Certificate is READY
- [ ] ClusterRoleBinding exists
- [ ] Can access https://kubernetes-dashboard.home.planetlauritsen.com
- [ ] OAuth login works
- [ ] Dashboard loads with full admin access

## Cleanup (After Successful Deployment)

Once everything is working, you can clean up old files:

```bash
cd /Users/csl04r/repos/cslauritsen/ansible-home

# Remove old helmfile configuration
rm -rf helmfile/kubernetes-dashboard/extras/
rm helmfile/kubernetes-dashboard/helmfile.yaml

# Remove old disabled ArgoCD app (if exists)
rm argocd/applications-disabled/kubernetes-dashboard.yaml

# Commit cleanup
git add .
git commit -m "Clean up old kubernetes-dashboard helmfile artifacts"
git push
```

## References

- **Migration Guide**: `helmfile/kubernetes-dashboard/MIGRATION-TO-ARGOCD.md`
- **Quick Reference**: `helmfile/kubernetes-dashboard/QUICKREF.md`
- **Summary**: `helmfile/kubernetes-dashboard/MIGRATION-SUMMARY.md`

---

**Time Estimate:** 15-30 minutes (assuming prerequisites are already deployed)

**Difficulty:** Medium

**Risk Level:** Low (can rollback via ArgoCD or re-deploy helmfile version)

