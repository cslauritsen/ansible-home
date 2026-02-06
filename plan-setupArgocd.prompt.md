# Plan: Setup ArgoCD with GitOps for RPI K3s Cluster

Deploy ArgoCD on your K3s cluster to enable GitOps-based deployment management, allowing you to update applications by committing to a GitHub repository. ArgoCD will monitor your Git repo and automatically sync changes to the cluster, replacing manual helmfile deployments with declarative GitOps workflows.

## Steps

1. **Deploy secret management solution** to eliminate laptop dependency:
   - Install External Secrets Operator OR Sealed Secrets controller
   - If using ESO, configure backend (AWS Secrets Manager free tier, or 1Password Connect if you have Business/Teams plan)
   - Create SecretStore/ClusterSecretStore resources to define how to access secrets
   - Test by converting one existing secret (e.g., from grafana or oauth2-proxy) to use new system

2. Create `helmfile/argocd/helmfile.yaml` with ArgoCD helm chart configuration, namespace `argocd`, and ARM64-compatible image settings for Raspberry Pi

3. Add `values.yaml` in `helmfile/argocd/` to configure server ingress (using existing ingress-nginx), enable HTTPS with cert-manager annotations, and optionally integrate oauth2-proxy authentication

4. Create ArgoCD Application manifests in `helmfile/argocd/applications/` directory to define which GitHub repo paths ArgoCD should monitor and sync to your cluster

5. Configure GitHub repository connection in ArgoCD (via secret or UI) with read access credentials for your deployment repo

6. Migrate existing helmfile deployments to ArgoCD Applications by creating app-of-apps pattern or individual Application resources pointing to helmfile directories
   - Convert `op` CLI secret references to External Secrets or Sealed Secrets format

7. Deploy ArgoCD using `helmfile -f helmfile/argocd/helmfile.yaml apply` and access the UI to configure repo connections and verify sync status

## Further Considerations

1. **Repository structure**: Keep this ansible-home repo for ArgoCD Applications, or create separate GitOps repo? 
   - **Recommendation**: Use this repo initially, separate later if needed.

2. **Secret management** (CRITICAL for laptop-free operation): 
   - **Current issue**: `op` CLI requires laptop to be connected and authenticated
   - **Option A - 1Password Connect Operator**: Runs in-cluster, provides API access to 1Password vaults
     - Requires 1Password **Business** or **Teams** plan (not included in Individual/Family plans)
     - Cost: No extra charge if you have Business/Teams plan
     - Best option if you already have the right plan
   - **Option B - External Secrets Operator (ESO)**: Generic solution, supports multiple backends
     - Works with 1Password Connect (requires Business/Teams plan)
     - Also works with AWS Secrets Manager, Azure Key Vault, HashiCorp Vault (free tiers available)
     - More flexible if you want to switch backends later
   - **Option C - Sealed Secrets**: Encrypt secrets in Git using asymmetric crypto
     - Free and simple, no external dependencies
     - Secrets stored encrypted in Git, cluster has private key to decrypt
     - Less convenient for secret rotation but fully self-contained
   - **Recommendation**: Start with **Sealed Secrets** (free, no dependencies) or **External Secrets Operator + AWS Secrets Manager free tier** if you don't have 1Password Business/Teams.

3. **Sync strategy**: Manual sync or automatic sync for ArgoCD Applications? 
   - **Recommendation**: Start with manual sync for safety, enable auto-sync per-application once comfortable.

4. **Authentication**: Expose ArgoCD with oauth2-proxy like Longhorn, use ArgoCD's built-in SSO (GitHub/Google), or use port-forward only? 
   - **Recommendation**: OAuth2-proxy for consistency with existing setup, or ArgoCD's built-in GitHub SSO for simpler configuration.

