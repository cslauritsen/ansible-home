# Plan: Add Helm Dashboard ArgoCD Application with Cluster-Admin Access

Create an ArgoCD Application for Helm Dashboard using remote Komodorio chart repository, with dedicated service account having cluster-admin privileges for comprehensive Kubernetes management.

## Steps

### 1. Create ArgoCD Application manifest
**File:** `argocd/applications/helm-dashboard.yaml`

Create ArgoCD Application referencing remote `komodorio/helm-dashboard` chart with custom values configuration. Follow the same pattern as headlamp application with dual sources (chart + RBAC resources).

### 2. Create RBAC resources  
**File:** `argocd/charts/helm-dashboard/rsrc/rbac.yaml`

Create ServiceAccount and ClusterRoleBinding for cluster-admin access, following the same pattern as headlamp:
- ServiceAccount: `helm-dashboard-admin` in `helm-dashboard` namespace
- ClusterRoleBinding: Grant `cluster-admin` role to the service account

### 3. Create values configuration
**File:** `argocd/charts/helm-dashboard/values-rpi.yaml`

Configure Helm Dashboard with:
- Service account reference to `helm-dashboard-admin`
- Enable cluster mode (`HD_CLUSTER_MODE=true`)
- Set appropriate resource limits for Raspberry Pi environment
- Configure ingress if needed for external access

### 4. Update root app-of-apps
**Verification:** `argocd/app-of-apps/root-app.yaml`

Ensure the root application will automatically discover and deploy the new helm-dashboard application from the applications directory.

## Implementation Details

### Chart Repository
- **Repository:** `https://helm-charts.komodor.io`
- **Chart:** `komodorio/helm-dashboard`
- **Remote reference:** No need to vendor chart locally

### RBAC Pattern
Follow existing headlamp RBAC pattern:
```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: helm-dashboard-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: helm-dashboard-admin
    namespace: helm-dashboard
```

### ArgoCD Application Structure
Use multi-source configuration:
- **Source 1:** Remote helm chart from komodorio repository
- **Source 2:** Local RBAC resources from `argocd/charts/helm-dashboard/rsrc/`

### Deployment Configuration
- **Namespace:** `helm-dashboard` (dedicated namespace)
- **Service Account:** `helm-dashboard-admin` with cluster-admin privileges
- **Sync Policy:** Automated with prune and self-heal enabled
- **Create Namespace:** True

## Further Considerations

### Security
- Cluster-admin privileges provide full cluster access - appropriate for dashboard functionality
- Consider network policies if additional security isolation needed

### Access Methods
Ingress configuration for external access (similar to headlamp pattern), use oauth2-proxy to secure access.
Ensure a cert-manager `Certificate` object is created for the ingress domain to enable TLS.

### Authentication
- Require passing through oauth2-proxy for authentication, leveraging existing OIDC setup

### Resource Requirements
- Configure appropriate resource limits for Raspberry Pi cluster
- Enable cluster mode for automatic repository updates and enhanced functionality

## Success Criteria
1. ArgoCD Application deploys successfully
2. Helm Dashboard pod runs with cluster-admin service account
3. Dashboard accessible via chosen access method
4. Full cluster visibility and Helm release management functionality available
5. Automatic sync and healing configured via ArgoCD
