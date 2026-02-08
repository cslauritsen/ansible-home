# Kubernetes Dashboard Migration - Summary

## ✅ Migration Complete!

Your kubernetes-dashboard has been successfully migrated from helmfile to ArgoCD with OAuth2-proxy authentication.

## What Was Created

### 1. ArgoCD Application Manifest
**File**: `/argocd/applications/kubernetes-dashboard.yaml`

This is a multi-source ArgoCD application that:
- Deploys the upstream kubernetes-dashboard Helm chart
- Configures ingress with OAuth2-proxy authentication annotations
- Includes additional RBAC manifests from your git repo
- Automatically syncs changes (prune and self-heal enabled)

### 2. RBAC Configuration
**File**: `/helmfile/kubernetes-dashboard/argocd-extras/rbac.yaml`

Creates:
- `oauth2-dashboard-admin` ServiceAccount
- ClusterRoleBinding granting cluster-admin to OAuth2-authenticated users
- Binds to both the custom SA and the chart's default SA

### 3. Documentation
- **Migration Guide**: `/helmfile/kubernetes-dashboard/MIGRATION-TO-ARGOCD.md` (comprehensive)
- **Quick Reference**: `/helmfile/kubernetes-dashboard/QUICKREF.md` (common commands)

## Key Benefits

### ✨ No More Token Management
- **Before**: Extract token from secret, copy/paste into dashboard login
- **After**: Navigate to URL, authenticate via OAuth2, automatic admin access

### ✨ Simplified Configuration
- **Before**: helmfile with chartlify + extras directory (3 separate files)
- **After**: Single ArgoCD application with inline values

### ✨ Better Security
- OAuth2-proxy validates users before they reach the dashboard
- Only whitelisted emails can access
- No shared tokens
- TLS everywhere (cert-manager + Let's Encrypt)

### ✨ GitOps Native
- All configuration in Git
- ArgoCD manages deployment lifecycle
- Automatic syncing and self-healing
- Full audit trail

## What You Can Delete (After Verification)

Once you've verified the new setup works:

```bash
# Old helmfile configuration
rm -rf helmfile/kubernetes-dashboard/extras/
rm helmfile/kubernetes-dashboard/helmfile.yaml

# Old disabled ArgoCD app (if it exists)
rm argocd/applications-disabled/kubernetes-dashboard.yaml
```

## Next Steps

### 1. Ensure Prerequisites

Before deploying, make sure these are running:

```bash
# Check oauth2-proxy
kubectl get pods -n oauth2-proxy

# Check cert-manager
kubectl get pods -n cert-manager

# Check nginx-ingress
kubectl get pods -n ingress-nginx

# Verify your email is in the whitelist
kubectl get configmap allowed-emails -n oauth2-proxy -o jsonpath='{.data.allowed-emails\.txt}'
```

### 2. Deploy

If using app-of-apps pattern (root-app.yaml), ArgoCD will automatically detect and deploy the application.

Manually deploy/sync:
```bash
# Apply the application
kubectl apply -f argocd/applications/kubernetes-dashboard.yaml

# Or sync via ArgoCD CLI
argocd app sync kubernetes-dashboard

# Watch deployment
kubectl get application kubernetes-dashboard -n argocd -w
```

### 3. Test Access

1. Open: https://kubernetes-dashboard.home.planetlauritsen.com
2. Should redirect to oauth2-proxy for authentication
3. Authenticate with your Google account (must be in whitelist)
4. Automatically land in dashboard with full admin access
5. Enjoy! 🎉

### 4. Verify RBAC

```bash
# Check ClusterRoleBinding
kubectl get clusterrolebinding oauth2-dashboard-admin

# Verify it grants cluster-admin
kubectl describe clusterrolebinding oauth2-dashboard-admin

# Check dashboard can list resources
kubectl auth can-i --list --as=system:serviceaccount:kubernetes-dashboard:kubernetes-dashboard
```

## Architecture Diagram

```
┌─────────┐
│  User   │
└────┬────┘
     │ 1. Navigate to https://kubernetes-dashboard.home.planetlauritsen.com
     ▼
┌─────────────────┐
│ nginx-ingress   │
│ (with auth      │
│  annotations)   │
└────┬────────────┘
     │ 2. Check auth via oauth2-proxy
     ▼
┌─────────────────┐
│  oauth2-proxy   │
│  (Google OAuth) │
└────┬────────────┘
     │ 3. Validate email in whitelist
     │    (/helmfile/oauth2-proxy/rsrc/allowed-emails.yaml)
     ▼
┌─────────────────┐
│   Google OAuth  │
│   (User Login)  │
└────┬────────────┘
     │ 4. Return to nginx-ingress with auth headers
     ▼
┌─────────────────┐
│   Dashboard     │
│   (cluster-     │
│    admin SA)    │
└─────────────────┘
```

## Configuration Reference

### OAuth2-Proxy Annotations (in ArgoCD App)

```yaml
nginx.ingress.kubernetes.io/auth-signin: https://oauth2-proxy.home.planetlauritsen.com/oauth2/start?rd=https://$host$request_uri
nginx.ingress.kubernetes.io/auth-url: https://oauth2-proxy.home.planetlauritsen.com/oauth2/auth
nginx.ingress.kubernetes.io/auth-response-headers: X-Auth-Request-User,X-Auth-Request-Email
```

### TLS Configuration

```yaml
cert-manager.io/cluster-issuer: letsencrypt-dns
```

### Backend Protocol

```yaml
nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
```

## Comparison: Before vs After

| Aspect | Helmfile (Before) | ArgoCD + OAuth2 (After) |
|--------|------------------|------------------------|
| **Authentication** | Token-based (manual) | OAuth2 (automatic) |
| **User Management** | Service account tokens | Email whitelist |
| **Configuration** | 2 releases, 3+ files | 1 app, inline values |
| **Deployment Tool** | helmfile CLI | ArgoCD (GitOps) |
| **Ingress** | Custom chartlify manifest | Helm chart values |
| **RBAC** | Custom manifests | Git-managed extras |
| **Sync** | Manual `helmfile apply` | Auto-sync or manual |
| **Audit Trail** | Git commits only | Git + ArgoCD history |
| **Rollback** | `helmfile destroy` + reapply | ArgoCD rollback |

## Troubleshooting Quick Links

**403 Forbidden after OAuth login:**
- Check: Your email is in `/helmfile/oauth2-proxy/rsrc/allowed-emails.yaml`
- Fix: Add email, commit, push, sync oauth2-proxy app

**Certificate not working:**
- Check: `kubectl get certificate -n kubernetes-dashboard`
- Fix: `kubectl describe certificate kubernetes-dashboard-tls -n kubernetes-dashboard`

**Dashboard shows limited permissions:**
- Check: `kubectl get clusterrolebinding oauth2-dashboard-admin`
- Fix: `kubectl apply -f helmfile/kubernetes-dashboard/argocd-extras/rbac.yaml`

**OAuth2-proxy redirect loop:**
- Check: `kubectl logs -n oauth2-proxy -l app.kubernetes.io/name=oauth2-proxy`
- Fix: Verify oauth2-proxy configuration (client ID, secret, cookie secret)

## References

- **Migration Guide**: `/helmfile/kubernetes-dashboard/MIGRATION-TO-ARGOCD.md`
- **Quick Reference**: `/helmfile/kubernetes-dashboard/QUICKREF.md`
- **OAuth2-Proxy Setup**: `/argocd/README-OAUTH2-RBAC.md`
- **ArgoCD Documentation**: https://argo-cd.readthedocs.io/
- **Kubernetes Dashboard**: https://github.com/kubernetes/dashboard

---

**Need help?** Check the detailed migration guide at:
`/helmfile/kubernetes-dashboard/MIGRATION-TO-ARGOCD.md`

