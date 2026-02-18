# Headlamp OAuth2-Proxy Integration - Summary

## What Was Done

I've configured your Headlamp deployment to use OAuth2-Proxy as a reverse proxy with Google OAuth authentication to provide cluster admin privileges.

## Changes Made

### 1. Updated Headlamp Ingress Annotations
**File:** `/argocd/charts/headlamp/values-rpi.yaml`

Added OAuth2-Proxy authentication annotations to the ingress:
```yaml
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-dns
  nginx.ingress.kubernetes.io/auth-url: "https://oauth2-proxy.home.planetlauritsen.com/oauth2/auth"
  nginx.ingress.kubernetes.io/auth-signin: "https://oauth2-proxy.home.planetlauritsen.com/oauth2/start?rd=https://$host$request_uri"
  nginx.ingress.kubernetes.io/auth-response-headers: "Authorization,X-Auth-Request-User,X-Auth-Request-Email,X-Auth-Request-Access-Token"
```

This ensures:
- All requests to Headlamp are authenticated via OAuth2-Proxy
- The Google access token is passed to Headlamp in the headers
- User email and other auth info are also available

### 2. Configured Headlamp to Use Access Tokens
**File:** `/argocd/charts/headlamp/values-rpi.yaml`

Updated OIDC configuration:
```yaml
config:
  oidc:
    useAccessToken: true  # Changed from false
    meUserInfoURL: "https://oauth2-proxy.home.planetlauritsen.com/oauth2/userinfo"  # Added
```

This tells Headlamp to:
- Use the access token (not id_token) for Kubernetes API calls
- Fetch additional user info from OAuth2-Proxy's userinfo endpoint

### 3. Created Documentation
**File:** `/argocd/charts/headlamp/OAUTH2-TOKEN-GUIDE.md`

Comprehensive guide covering:
- How the OAuth2-Proxy token flow works
- How to extract tokens manually for testing
- RBAC configuration options
- Troubleshooting steps

### 4. Created Example RBAC Configuration
**File:** `/argocd/charts/headlamp/rsrc/oauth2-clusterrolebinding.yaml`

Example ClusterRoleBinding for mapping Google email addresses to cluster-admin role.

**Note:** This file is provided as a reference but is NOT active by default because:
- The Headlamp chart already creates a ClusterRoleBinding for its service account with cluster-admin
- For Google OAuth tokens to be recognized directly by Kubernetes, you need to configure the API server with OIDC settings

## How It Works Now

### Authentication Flow

```
User Browser
     ↓
1. Request: https://headlamp.home.planetlauritsen.com
     ↓
nginx-ingress (checks auth via oauth2-proxy)
     ↓
2. Redirects to: https://oauth2-proxy.home.planetlauritsen.com
     ↓
3. OAuth2-Proxy redirects to Google
     ↓
4. User authenticates with Google
     ↓
5. Google returns tokens to OAuth2-Proxy
     ↓
6. OAuth2-Proxy sets session cookie & forwards to Headlamp with:
   - Authorization: Bearer <access_token>
   - X-Auth-Request-User: <email>
   - X-Auth-Request-Email: <email>
   - X-Auth-Request-Access-Token: <token>
     ↓
7. Headlamp receives request with auth headers
     ↓
8. Headlamp uses its ServiceAccount token (has cluster-admin) to access K8s API
```

## Current Privilege Model

**Headlamp already has cluster-admin via its ServiceAccount**, configured in values:
```yaml
clusterRoleBinding:
  create: true
  clusterRoleName: cluster-admin
```

This means:
- ✅ Any user authenticated via OAuth2-Proxy can access Headlamp
- ✅ Headlamp has full cluster access via its service account
- ✅ Access control is enforced at the OAuth2-Proxy level (allowed-emails.txt)

## Alternative: Direct Google Token Authentication

If you want Kubernetes to validate the Google access token directly (instead of using Headlamp's service account), you need to:

### 1. Configure K3s API Server for OIDC

Edit `/etc/rancher/k3s/config.yaml` on your K3s nodes:
```yaml
kube-apiserver-arg:
  - "oidc-issuer-url=https://accounts.google.com"
  - "oidc-client-id=YOUR_GOOGLE_CLIENT_ID"
  - "oidc-username-claim=email"
  - "oidc-groups-claim=groups"
```

Then restart K3s:
```bash
sudo systemctl restart k3s
```

### 2. Apply the ClusterRoleBinding

Edit and apply the example binding:
```bash
# Edit to add your email
vi /Users/csl04r/repos/cslauritsen/ansible-home/argocd/charts/headlamp/rsrc/oauth2-clusterrolebinding.yaml

# Apply it
kubectl apply -f /Users/csl04r/repos/cslauritsen/ansible-home/argocd/charts/headlamp/rsrc/oauth2-clusterrolebinding.yaml
```

### 3. Update Headlamp Configuration

You would need to configure Headlamp to use token-based authentication instead of service account.

## Next Steps to Deploy

1. **Review the changes:**
   ```bash
   git diff argocd/charts/headlamp/values-rpi.yaml
   ```

2. **Commit the changes:**
   ```bash
   git add argocd/charts/headlamp/
   git commit -m "Configure Headlamp with OAuth2-Proxy authentication"
   git push
   ```

3. **Sync in ArgoCD:**
   - Go to ArgoCD UI
   - Find the "headlamp" application
   - Click "Sync"
   - Or use CLI: `argocd app sync headlamp`

4. **Test the authentication:**
   - Clear browser cookies for `.planetlauritsen.com`
   - Navigate to: `https://headlamp.home.planetlauritsen.com`
   - Should redirect to Google OAuth login
   - After authentication, should land in Headlamp with full cluster access

## Verifying It Works

### Check Ingress Annotations
```bash
kubectl get ingress -n headlamp headlamp -o yaml | grep auth
```

Should show the oauth2-proxy annotations.

### Check Headlamp Pod
```bash
kubectl get pod -n headlamp
kubectl logs -n headlamp deployment/headlamp
```

### Test Authentication Flow
1. Open browser in incognito mode
2. Go to `https://headlamp.home.planetlauritsen.com`
3. Should redirect to Google
4. After login, should redirect back to Headlamp
5. Check browser dev tools → Network → Headers for auth headers

### Verify RBAC
```bash
# Check Headlamp's service account permissions
kubectl auth can-i --list --as=system:serviceaccount:headlamp:headlamp

# Check ClusterRoleBinding
kubectl get clusterrolebinding | grep headlamp
```

## Troubleshooting

### Not Redirecting to OAuth2-Proxy
- Check ingress annotations are applied: `kubectl get ingress -n headlamp headlamp -o yaml`
- Check nginx-ingress logs: `kubectl logs -n ingress-nginx deployment/ingress-nginx-controller`

### Authentication Loop
- Clear all cookies for `.planetlauritsen.com`
- Verify your email is in `/helmfile/oauth2-proxy/rsrc/allowed-emails.yaml`
- Check oauth2-proxy logs: `kubectl logs -n oauth2-proxy deployment/oauth2-proxy`

### Headlamp Shows "Not Authenticated"
- Check that `useAccessToken: true` is set
- Verify the auth-response-headers annotation includes the token
- Check Headlamp logs for authentication errors

## Summary

The key insight is that **Headlamp already has cluster-admin privileges** via its ServiceAccount. OAuth2-Proxy serves as the **gate-keeper** to control who can access Headlamp's interface. The Google access token is passed through but Headlamp uses its own service account token for Kubernetes API calls.

This is the simplest and most common setup. If you need more granular per-user RBAC based on Google identity, you would need to configure Kubernetes API server OIDC settings and configure Headlamp differently.

