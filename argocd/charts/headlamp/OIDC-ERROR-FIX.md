# Fix for Headlamp OIDC Error: "Failed to verify ID Token"

## Problem

When trying to sign on to Headlamp with OIDC, the following error occurred:
```
Failed to verify ID Token: oidc: failed to unmarshal claims: invalid character '\x03' looking for beginning of value
```

## Root Cause

The error occurred because Headlamp was configured with **both** OAuth2-Proxy authentication AND direct OIDC configuration. This caused a conflict:

1. **OAuth2-Proxy** was authenticating users via Google OAuth2
2. **Headlamp** was also configured with OIDC settings (issuerURL, useAccessToken, etc.)
3. When Headlamp received the authentication token from OAuth2-Proxy, it tried to verify it as an OIDC token against Google's issuer
4. The token format didn't match expectations, causing the unmarshal error

## Solution

When using **OAuth2-Proxy as an authentication proxy**, Headlamp should NOT have OIDC configuration enabled. Instead:

- **OAuth2-Proxy** handles all user authentication (login via Google)
- **Headlamp** uses its Kubernetes ServiceAccount for API access
- The ServiceAccount has cluster-admin permissions via ClusterRoleBinding

## Changes Made

### File: `/argocd/charts/headlamp/values-rpi.yaml`

**Disabled all OIDC configuration:**
```yaml
config:
  oidc:
    secret:
      create: false
      name: ""
    
    # All OIDC fields set to empty/false
    clientID: ""
    clientSecret: ""
    issuerURL: ""              # Was: "https://accounts.google.com"
    scopes: ""
    callbackURL: ""            # Was: "https://headlamp.home.planetlauritsen.com/oidc-callback"
    validatorClientID: ""
    validatorIssuerURL: ""
    useAccessToken: false      # Was: true
    usePKCE: false
    
    # External secret disabled
    externalSecret:
      enabled: false           # Was: true
      name: ""                 # Was: "headlamp-oidc-manual"
    
    # User info URL disabled
    meUserInfoURL: ""          # Was: "https://oauth2-proxy.home.planetlauritsen.com/oauth2/userinfo"
```

**Kept OAuth2-Proxy authentication:**
```yaml
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-dns
    # OAuth2-Proxy authentication annotations remain
    nginx.ingress.kubernetes.io/auth-url: "https://oauth2-proxy.home.planetlauritsen.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth2-proxy.home.planetlauritsen.com/oauth2/start?rd=https://$host$request_uri"
    nginx.ingress.kubernetes.io/auth-response-headers: "Authorization,X-Auth-Request-User,X-Auth-Request-Email,X-Auth-Request-Access-Token"
```

## How It Works Now

1. User navigates to `https://headlamp.home.planetlauritsen.com`
2. **nginx-ingress** sees the auth annotations and redirects to OAuth2-Proxy
3. **OAuth2-Proxy** authenticates user via Google OAuth2
4. After successful authentication, OAuth2-Proxy passes headers to Headlamp
5. **Headlamp** accepts the authenticated request (no OIDC verification)
6. **Headlamp** uses its ServiceAccount token to access the Kubernetes API
7. ServiceAccount has cluster-admin permissions, so user gets full access

## Authentication Flow

```
User → nginx-ingress → OAuth2-Proxy → Google OAuth2
                             ↓
                     [User authenticated]
                             ↓
User ← Headlamp ← OAuth2-Proxy (with auth headers)
       |
       └→ K8s API (using ServiceAccount token)
```

## Deployment Steps

1. **Review the changes:**
   ```bash
   git diff argocd/charts/headlamp/values-rpi.yaml
   ```

2. **Commit the changes:**
   ```bash
   git add argocd/charts/headlamp/values-rpi.yaml
   git commit -m "Fix Headlamp OIDC error by disabling OIDC when using OAuth2-Proxy"
   git push
   ```

3. **Sync in ArgoCD:**
   - Navigate to ArgoCD UI
   - Find the "headlamp" application
   - Click "Sync" and "Synchronize"
   - Or use CLI: `argocd app sync headlamp`

4. **Wait for deployment to complete:**
   ```bash
   kubectl rollout status deployment/headlamp -n default
   ```

5. **Test the fix:**
   - Clear browser cookies for `.planetlauritsen.com`
   - Navigate to: `https://headlamp.home.planetlauritsen.com`
   - Should redirect to Google OAuth login
   - After authentication, should land in Headlamp without errors
   - Should have full cluster access via cluster-admin permissions

## Verification

Check that Headlamp is running without OIDC configuration:
```bash
# View the deployment environment variables
kubectl get deployment headlamp -n default -o yaml | grep -A 20 "env:"

# Should NOT see any OIDC_* environment variables
# Should only see standard Kubernetes env vars
```

Check the pods are healthy:
```bash
kubectl get pods -n default -l app.kubernetes.io/name=headlamp
kubectl logs -n default -l app.kubernetes.io/name=headlamp --tail=50
```

## Security Notes

- **Access Control:** Anyone who can authenticate via OAuth2-Proxy (your Google account) will have cluster-admin access
- **ServiceAccount:** The headlamp ServiceAccount has cluster-admin permissions
- **No per-user RBAC:** All authenticated users get the same permissions (cluster-admin)

If you need per-user RBAC based on Google identity, you would need to:
1. Configure the Kubernetes API server with OIDC settings
2. Re-enable Headlamp OIDC (without OAuth2-Proxy)
3. Create ClusterRoleBindings for each Google user/group

## Troubleshooting

If you still see errors:

1. **Clear browser cache and cookies completely**
2. **Check Headlamp logs:**
   ```bash
   kubectl logs -n default -l app.kubernetes.io/name=headlamp --tail=100
   ```
3. **Verify OAuth2-Proxy is working:**
   ```bash
   curl -I https://oauth2-proxy.home.planetlauritsen.com/ping
   ```
4. **Check the secret was removed:**
   ```bash
   kubectl get secret headlamp-oidc-manual -n default
   # Should return "Error from server (NotFound)"
   ```

## References

- [Headlamp Documentation](https://headlamp.dev/)
- [OAuth2-Proxy Documentation](https://oauth2-proxy.github.io/oauth2-proxy/)
- [OAUTH2-TOKEN-GUIDE.md](./OAUTH2-TOKEN-GUIDE.md)
- [OAUTH2-INTEGRATION-SUMMARY.md](./OAUTH2-INTEGRATION-SUMMARY.md)

