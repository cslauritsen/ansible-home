# ArgoCD Applications

This directory contains ArgoCD Application manifests that enable GitOps-based deployment management for the K3s cluster.

## Structure

```
helmfile/argocd/
├── app-of-apps/
│   └── root-app.yaml           # Root application that manages all other apps
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
└── README-APPLICATIONS.md      # This file
```

## App-of-Apps Pattern

The `root-app.yaml` implements the "App of Apps" pattern, which means:
- It's a single ArgoCD Application that manages all other Applications
- It watches the `applications/` directory for Application manifests
- When you add a new Application manifest, ArgoCD automatically discovers it
- Provides centralized control over all application deployments

## Application Configuration

Each application manifest follows this structure:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <app-name>
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io  # Ensures proper cleanup
spec:
  project: default
  source:
    repoURL: https://github.com/cslauritsen/ansible-home.git
    targetRevision: HEAD
    path: helmfile/<app-name>
    plugin:
      name: helmfile  # Uses ArgoCD helmfile plugin
  destination:
    server: https://kubernetes.default.svc
    namespace: <app-namespace>
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
```

## Sync Policies

### Manual Sync (Current Default)
All applications are configured for **manual sync** initially. This means:
- Changes in Git won't be applied automatically
- You must click "Sync" in the ArgoCD UI to apply changes
- Safer for initial setup and testing

### Automated Sync (Optional)
To enable automatic syncing, uncomment the `automated` section in each manifest:

```yaml
syncPolicy:
  automated:
    prune: true      # Remove resources deleted from Git
    selfHeal: true   # Revert manual changes to match Git
```

## Deployment Order

When deploying from scratch, follow this order:

1. **Infrastructure Layer** (dependencies for other apps):
   - `sealed-secrets` - Secret management
   - `metallb` - Load balancer
   - `cert-manager` - TLS certificates

2. **Networking Layer**:
   - `ingress-nginx` - Ingress controller
   - `oauth2-proxy` - Authentication proxy

3. **Storage Layer**:
   - `longhorn` - Persistent storage

4. **Observability Layer**:
   - `grafana` - Monitoring dashboards
   - `alloy` - Telemetry collector

5. **Application Layer** (can be deployed in any order):
   - `kubernetes-dashboard`
   - `mongodb`
   - `rabbitmq`
   - `kafka`

## Deploying the Root Application

To deploy the root app-of-apps (once ArgoCD is installed):

```bash
kubectl apply -f helmfile/argocd/app-of-apps/root-app.yaml
```

This will create all child applications in the ArgoCD UI.

## Managing Applications

### Via ArgoCD UI

1. Access ArgoCD UI: `https://argocd.home.planetlauritsen.com`
2. Click on an application to see its status
3. Click "Sync" to apply changes from Git
4. Use "App Diff" to preview changes before syncing

### Via ArgoCD CLI

```bash
# Login
argocd login argocd.home.planetlauritsen.com

# List all applications
argocd app list

# Get application status
argocd app get <app-name>

# Sync an application
argocd app sync <app-name>

# Sync all applications
argocd app sync -l app.kubernetes.io/instance=root-app
```

## Adding New Applications

To add a new application:

1. Create a new YAML file in `applications/` directory
2. Follow the template structure shown above
3. Commit and push to GitHub
4. The root app will automatically discover it
5. Sync the new application via UI or CLI

## Notes

- **Repository URL**: Update `repoURL` in all manifests if repository location changes
- **Helmfile Plugin**: Requires ArgoCD helmfile plugin to be installed
- **Secrets**: Use Sealed Secrets for sensitive data (see Phase 5 of implementation plan)
- **Dependencies**: Some applications depend on others (e.g., ingress-nginx needs metallb)

## Troubleshooting

### Application stuck in "Progressing"
- Check pod status: `kubectl get pods -n <namespace>`
- View ArgoCD logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller`

### Sync fails with "OutOfSync"
- Click "App Diff" to see what changed
- Verify helmfile syntax: `helmfile -f helmfile/<app>/helmfile.yaml lint`
- Check for secret issues (may need to convert to sealed secrets)

### Application not appearing
- Verify root-app is synced: `kubectl get application -n argocd root-app`
- Check root-app logs for errors
- Ensure new manifest is committed to Git

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [ArgoCD Helmfile Plugin](https://github.com/travisghansen/argo-cd-helmfile)

