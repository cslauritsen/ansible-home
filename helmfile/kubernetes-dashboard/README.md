# Kubernetes Dashboard

## Current Status: ArgoCD-Managed with OAuth2-Proxy Authentication

This application has been **migrated from helmfile to ArgoCD** with OAuth2-proxy authentication.

### 🚀 Quick Access
- **URL**: https://kubernetes-dashboard.home.planetlauritsen.com
- **Authentication**: OAuth2 via oauth2-proxy (Google OAuth)
- **Authorization**: Automatic cluster-admin for whitelisted users

### 📁 Files

#### Active Files (ArgoCD)
- `/argocd/applications/kubernetes-dashboard.yaml` - ArgoCD Application manifest
- `argocd-extras/rbac.yaml` - RBAC ClusterRoleBinding for admin access

#### Documentation
- **[DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md)** - 👈 **Start here** for deployment
- **[MIGRATION-TO-ARGOCD.md](MIGRATION-TO-ARGOCD.md)** - Comprehensive migration guide
- **[MIGRATION-SUMMARY.md](MIGRATION-SUMMARY.md)** - High-level overview
- **[QUICKREF.md](QUICKREF.md)** - Quick reference commands

#### Deprecated Files (Can be removed after verification)
- `extras/` - Old helmfile chartlify manifests
- `helmfile.yaml` - Old helmfile configuration

### 🔧 Quick Commands

```bash
# Check application status
kubectl get application kubernetes-dashboard -n argocd

# Check pods
kubectl get pods -n kubernetes-dashboard

# Sync application
argocd app sync kubernetes-dashboard

# View logs
kubectl logs -n kubernetes-dashboard -l app.kubernetes.io/name=kubernetes-dashboard
```

### 📋 Prerequisites

1. ✅ OAuth2-proxy deployed and running
2. ✅ Your email in oauth2-proxy whitelist: `/helmfile/oauth2-proxy/rsrc/allowed-emails.yaml`
3. ✅ nginx-ingress deployed
4. ✅ cert-manager deployed

### 📚 More Information

See **[DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md)** for complete deployment instructions.

