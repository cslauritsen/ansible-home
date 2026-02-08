# Kubernetes Dashboard - Quick Reference

## Access URL
https://kubernetes-dashboard.home.planetlauritsen.com

## Authentication
- **Method**: OAuth2-Proxy with Google OAuth
- **Whitelist**: `/helmfile/oauth2-proxy/rsrc/allowed-emails.yaml`
- **No token required** - automatic admin access after OAuth login

## Quick Status Check
```bash
# Application status
kubectl get application kubernetes-dashboard -n argocd

# Pods
kubectl get pods -n kubernetes-dashboard

# Ingress
kubectl get ingress -n kubernetes-dashboard

# RBAC
kubectl get clusterrolebinding oauth2-dashboard-admin
```

## Quick Sync
```bash
# Via ArgoCD CLI
argocd app sync kubernetes-dashboard

# Via kubectl
kubectl patch application kubernetes-dashboard -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"normal"}}}'
```

## Add User to Whitelist
1. Edit: `/helmfile/oauth2-proxy/rsrc/allowed-emails.yaml`
2. Add email to the list
3. Commit and push
4. Sync oauth2-proxy: `argocd app sync oauth2-proxy`

## Troubleshooting Commands
```bash
# Check oauth2-proxy logs
kubectl logs -n oauth2-proxy -l app.kubernetes.io/name=oauth2-proxy -f

# Check nginx-ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f | grep kubernetes-dashboard

# Check dashboard logs
kubectl logs -n kubernetes-dashboard -l app.kubernetes.io/name=kubernetes-dashboard -f

# Check certificate
kubectl get certificate -n kubernetes-dashboard
kubectl describe certificate kubernetes-dashboard-tls -n kubernetes-dashboard
```

## Files
- Application: `/argocd/applications/kubernetes-dashboard.yaml`
- RBAC: `/helmfile/kubernetes-dashboard/argocd-extras/rbac.yaml`
- Migration Guide: `/helmfile/kubernetes-dashboard/MIGRATION-TO-ARGOCD.md`

