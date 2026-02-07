# ArgoCD Extras

## TLS Certificate

ArgoCD uses a wildcard certificate for `*.home.planetlauritsen.com`:
- Certificate: `wildcard-home-planetlauritsen` created in the `argocd` namespace
- Secret: `wildcard-home-planetlauritsen-tls` 
- Covers: `argocd.home.planetlauritsen.com` (and all other `*.home.planetlauritsen.com` subdomains)
- Managed by: cert-manager using the `letsencrypt-dns` ClusterIssuer

### Certificate Management Strategy

Each namespace that needs the wildcard certificate creates its own Certificate resource pointing to the same ClusterIssuer. This approach:
- Keeps certificates managed by cert-manager (GitOps-friendly)
- Ensures each namespace owns its TLS secret
- Lets cert-manager handle renewals automatically
- Doesn't require additional tools for secret syncing
- Doesn't hit Let's Encrypt rate limits (cert-manager is smart about caching)

## Authentication

ArgoCD is protected by oauth2-proxy configured in the ingress annotations:
- Auth URL: `https://oauth2-proxy.home.planetlauritsen.com/oauth2/auth`
- Sign-in URL: `https://oauth2-proxy.home.planetlauritsen.com/oauth2/start`

Users authenticate via GitHub OAuth through oauth2-proxy before accessing ArgoCD UI.

## Additional Resources

Place any additional Kubernetes manifests needed for ArgoCD here:
- ConfigMaps
- Secrets (sealed)
- RBAC resources
- Custom resource definitions

