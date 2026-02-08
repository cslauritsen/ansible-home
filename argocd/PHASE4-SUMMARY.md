# Phase 4 Summary - ArgoCD Applications Created

**Date Completed**: February 7, 2026  
**Status**: ✅ Complete - Ready for Phase 5

## What Was Created

### Directory Structure
```
helmfile/argocd/
├── app-of-apps/
│   └── root-app.yaml           # Root Application (App of Apps pattern)
├── applications/
│   ├── alloy.yaml
│   ├── cert-manager.yaml
│   ├── grafana.yaml
│   ├── ingress-nginx.yaml
│   ├── kafka.yaml
│   ├── kubernetes-dashboard.yaml
│   ├── longhorn.yaml
│   ├── metallb.yaml
│   ├── mongodb.yaml
│   ├── oauth2-proxy.yaml
│   ├── rabbitmq.yaml
│   └── sealed-secrets.yaml
└── README-APPLICATIONS.md      # Comprehensive documentation
```

## Applications Overview

### Infrastructure Layer (Deploy First)
1. **sealed-secrets** - Secret management controller
   - Namespace: `kube-system`
   - Critical for all applications with secrets

2. **metallb** - Load balancer for bare metal
   - Namespace: `metallb-system`
   - Required by ingress-nginx

3. **cert-manager** - TLS certificate management
   - Namespace: `cert-manager`
   - Required by applications needing HTTPS

### Networking Layer
4. **ingress-nginx** - Ingress controller
   - Namespace: `ingress-nginx`
   - Depends on: metallb

5. **oauth2-proxy** - Authentication proxy
   - Namespace: `oauth2-proxy`
   - Protects other applications

### Storage Layer
6. **longhorn** - Distributed block storage
   - Namespace: `longhorn-system`
   - Required by stateful applications

### Observability Layer
7. **grafana** - Monitoring dashboards
   - Namespace: `grafana`

8. **alloy** - Telemetry collector
   - Namespace: `alloy`

### Application Layer
9. **kubernetes-dashboard** - Kubernetes UI
   - Namespace: `kubernetes-dashboard`

10. **mongodb** - NoSQL database
    - Namespace: `mongodb`

11. **rabbitmq** - Message broker
    - Namespace: `rabbitmq`

12. **kafka** - Event streaming platform
    - Namespace: `kafka`

## Configuration Details

### Repository Settings
- **Repository URL**: `https://github.com/cslauritsen/ansible-home.git`
- **Target Revision**: `HEAD` (tracks default branch)
- **Source Type**: Helmfile plugin

### Sync Policy
All applications are configured with:
- ✅ **Manual sync** enabled (safe for initial deployment)
- ✅ **CreateNamespace** enabled
- ⏸️ **Auto-sync** disabled (commented out, can enable later)
- ⏸️ **Prune** disabled (commented out)
- ⏸️ **Self-heal** disabled (commented out)

### Finalizers
All applications include `resources-finalizer.argocd.argoproj.io` to ensure proper cleanup on deletion.

## How It Works: App-of-Apps Pattern

1. **Root Application** (`root-app.yaml`) is deployed to ArgoCD
2. Root app watches `helmfile/argocd/applications/` directory
3. ArgoCD automatically discovers all YAML files in that directory
4. Each file becomes a child Application in ArgoCD
5. You can sync applications individually or in bulk

## Next Steps - Phase 5

Before deploying the root application, you need to:

1. **Convert secrets to Sealed Secrets**:
   - Grafana Cloud credentials
   - OAuth2-proxy client secrets
   - Cert-manager Cloudflare API token
   - Database passwords
   - Other 1Password-managed secrets

2. **Update helmfiles** to reference sealed secrets instead of `op://` references

3. **Test sealed secret creation** before committing to Git

## Deployment Commands (Do Not Run Yet!)

These commands will be used in Phase 6:

```bash
# Step 1: Deploy the root application
kubectl apply -f helmfile/argocd/app-of-apps/root-app.yaml

# Step 2: View all applications in ArgoCD
argocd app list

# Step 3: Sync applications in order
argocd app sync sealed-secrets
argocd app sync metallb
argocd app sync cert-manager
argocd app sync ingress-nginx
# ... continue with others
```

## Important Notes

### Before Deployment
- ⚠️ **DO NOT apply root-app.yaml yet** - secrets must be converted first
- ⚠️ Ensure GitHub repository is accessible
- ⚠️ Verify helmfile plugin is installed in ArgoCD (done in Phase 2)

### After Phase 5 (Secret Conversion)
- All `op://` references will be replaced with sealed secrets
- Sealed secrets will be committed to Git (safe - they're encrypted)
- Applications can be deployed without 1Password dependency

### Repository URL
If your repository URL is different, update the `repoURL` field in all application manifests:
```bash
# Find and replace in all files
cd helmfile/argocd
grep -r "repoURL:" app-of-apps/ applications/
# Update as needed
```

## Validation Checklist

- [x] All 12 application manifests created
- [x] Root app-of-apps manifest created
- [x] All applications reference correct helmfile paths
- [x] All applications use helmfile plugin
- [x] Sync policies set to manual initially
- [x] CreateNamespace enabled for all apps
- [x] Documentation created (README-APPLICATIONS.md)
- [ ] Secrets converted to sealed secrets (Phase 5)
- [ ] Root application deployed (Phase 6)
- [ ] Applications synced and healthy (Phase 6)

## Troubleshooting

### If helmfile plugin is not found
```bash
# Check ArgoCD ConfigMap for plugin definition
kubectl get configmap argocd-cm -n argocd -o yaml | grep -A 10 helmfile
```

### If repository connection fails
```bash
# Test in ArgoCD UI: Settings → Repositories → Add
# Or check existing connection:
argocd repo list
```

### If applications don't appear
```bash
# Check root-app status
kubectl get application root-app -n argocd -o yaml

# Check ArgoCD application controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

## References

- [ArgoCD App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [ArgoCD Application Spec](https://argo-cd.readthedocs.io/en/stable/operator-manual/application.yaml)
- [Helmfile Plugin for ArgoCD](https://github.com/travisghansen/argo-cd-helmfile)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)

---

**Phase 4 Status**: ✅ **COMPLETE**  
**Next Phase**: Phase 5 - Convert Secrets to Sealed Secrets  
**Estimated Time for Phase 5**: 2-3 hours

