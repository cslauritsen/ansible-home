# Getting Google Access Token via OAuth2-Proxy for Headlamp Authentication

## Overview

When using OAuth2-Proxy as a reverse proxy in front of Headlamp, you have two main approaches to authenticate with the Kubernetes cluster:

1. **Use OAuth2-Proxy to pass the access token to Headlamp** (Recommended)
2. **Extract the token manually from browser cookies/headers**

## Current Setup

Based on your configuration:

- **OAuth2-Proxy** is configured with `--pass-access-token=true` ✅
- **Headlamp** has OIDC configuration but **NO oauth2-proxy ingress annotations** ⚠️

This means Headlamp is currently accessible WITHOUT oauth2-proxy authentication.

## Option 1: Add OAuth2-Proxy Authentication to Headlamp (Recommended)

### Step 1: Add OAuth2-Proxy Annotations to Headlamp Ingress

You need to protect Headlamp with oauth2-proxy by adding authentication annotations.

**File:** `/argocd/charts/headlamp/values-rpi.yaml`

```yaml
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-dns
    # Add these oauth2-proxy annotations:
    nginx.ingress.kubernetes.io/auth-url: "https://oauth2-proxy.home.planetlauritsen.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth2-proxy.home.planetlauritsen.com/oauth2/start?rd=https://$host$request_uri"
    nginx.ingress.kubernetes.io/auth-response-headers: "Authorization,X-Auth-Request-User,X-Auth-Request-Email,X-Auth-Request-Access-Token"
  ingressClassName: "nginx"
  hosts:
    - host: headlamp.home.planetlauritsen.com
      paths:
        - path: /
          type: Prefix
  tls:
    - secretName: headlamp-tls
      hosts:
        - headlamp.home.planetlauritsen.com
```

**Key annotation:** `nginx.ingress.kubernetes.io/auth-response-headers` passes the Google access token to Headlamp.

### Step 2: Configure Headlamp to Accept the Token

Headlamp needs to know how to use the token passed by oauth2-proxy. Update the OIDC configuration:

```yaml
config:
  oidc:
    # Use the external secret for OIDC config
    externalSecret:
      enabled: true
      name: headlamp-oidc
    
    # Tell Headlamp to use the access token instead of id_token
    useAccessToken: true
    
    # Optional: Configure to fetch user info from oauth2-proxy
    meUserInfoURL: "https://oauth2-proxy.home.planetlauritsen.com/oauth2/userinfo"
```

### Step 3: Verify OAuth2-Proxy Configuration

Your oauth2-proxy is already well-configured with:

```yaml
extraArgs:
  - --pass-access-token=true          # ✅ Passes token to backend
  - --set-authorization-header=true   # ✅ Sets Authorization header
```

### Step 4: Configure Kubernetes RBAC

To grant cluster admin privileges to authenticated users, you need a ClusterRoleBinding that maps the Google email to cluster-admin role.

**File:** `/argocd/charts/headlamp/rsrc/oauth2-clusterrolebinding.yaml`

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: headlamp-oauth2-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  # Grant to the headlamp service account
  - kind: ServiceAccount
    name: headlamp
    namespace: headlamp
  # Or grant directly to Google users
  - kind: User
    name: your-email@gmail.com
    apiGroup: rbac.authorization.k8s.io
```

## Option 2: Extract Token Manually (For Testing)

If you want to manually extract the Google access token for testing:

### Method A: Browser Developer Tools

1. Open Headlamp: `https://headlamp.home.planetlauritsen.com`
2. Authenticate via OAuth2-Proxy
3. Open Browser Developer Tools (F12)
4. Go to **Network** tab
5. Look for requests to Headlamp
6. Check the request headers for:
   - `Authorization: Bearer <token>`
   - `X-Auth-Request-Access-Token: <token>`
7. Copy the token value

### Method B: Check Browser Cookies

1. After authenticating, open Browser Developer Tools
2. Go to **Application** → **Cookies**
3. Look for cookies from `oauth2-proxy.home.planetlauritsen.com` or `.planetlauritsen.com`
4. The `_oauth2_proxy` cookie contains the session
5. **Note:** The actual access token is stored server-side; the cookie is just a session reference

### Method C: Use OAuth2-Proxy Debug Endpoint

OAuth2-Proxy has a debug endpoint that shows token information:

```bash
# After authenticating in browser, make a request to the userinfo endpoint
curl -H "Cookie: _oauth2_proxy=YOUR_COOKIE_VALUE" \
  https://oauth2-proxy.home.planetlauritsen.com/oauth2/userinfo
```

This will return user information and potentially the access token.

### Method D: Direct OAuth2 Flow (Advanced)

If you need the token programmatically:

```bash
# Step 1: Get authorization code
# Open in browser:
https://accounts.google.com/o/oauth2/v2/auth?\
  client_id=YOUR_CLIENT_ID&\
  redirect_uri=https://oauth2-proxy.home.planetlauritsen.com/oauth2/callback&\
  response_type=code&\
  scope=openid%20email%20profile&\
  state=random_state

# Step 2: Exchange code for token
curl -X POST https://oauth2.googleapis.com/token \
  -d "code=AUTHORIZATION_CODE" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "redirect_uri=https://oauth2-proxy.home.planetlauritsen.com/oauth2/callback" \
  -d "grant_type=authorization_code"
```

## How Tokens Flow with OAuth2-Proxy

```
┌──────────┐
│  User    │
│ Browser  │
└────┬─────┘
     │ 1. Request https://headlamp.home.planetlauritsen.com
     ▼
┌──────────────────┐
│  nginx-ingress   │
│  (auth check)    │
└────┬─────────────┘
     │ 2. Check auth via oauth2-proxy
     ▼
┌──────────────────┐
│  OAuth2-Proxy    │───► 3. Redirect to Google for auth
│                  │◄─── 4. Receive tokens from Google
└────┬─────────────┘
     │ 5. Set cookie & pass token in headers
     ▼
┌──────────────────┐
│    Headlamp      │
│                  │
│ • Receives:      │
│   - Authorization│
│   - Email        │
│   - Access Token │
└────┬─────────────┘
     │ 6. Use token to call K8s API
     ▼
┌──────────────────┐
│  Kubernetes API  │
│                  │
│ Validates token  │
│ Checks RBAC      │
└──────────────────┘
```

## Granting Cluster Admin via Google OAuth

For Kubernetes to accept the Google token and grant admin privileges:

### Option A: Use Service Account (Current Setup)

Your Headlamp deployment uses a ServiceAccount with a ClusterRoleBinding to cluster-admin:

```yaml
clusterRoleBinding:
  create: true
  clusterRoleName: cluster-admin
```

This means Headlamp's pod has cluster-admin via its service account token.

### Option B: Map Google Email to Cluster Admin

Configure Kubernetes API server to accept Google tokens:

1. **API Server Configuration** (requires cluster access to modify):

```yaml
# /etc/kubernetes/manifests/kube-apiserver.yaml (for kubeadm clusters)
# Or k3s config
spec:
  containers:
  - command:
    - kube-apiserver
    - --oidc-issuer-url=https://accounts.google.com
    - --oidc-client-id=YOUR_CLIENT_ID
    - --oidc-username-claim=email
    - --oidc-groups-claim=groups
```

2. **Create ClusterRoleBinding for your Google email:**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: google-oauth-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: User
    name: your-email@gmail.com
    apiGroup: rbac.authorization.k8s.io
```

### Option C: Use OAuth2-Proxy Impersonation (Hybrid)

Configure Headlamp to impersonate users based on oauth2-proxy headers:

This requires additional configuration in Headlamp and may not be fully supported.

## Troubleshooting

### Token Not Being Passed

Check nginx-ingress controller logs:

```bash
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller | grep headlamp
```

### Token Not Accepted by Kubernetes

Verify RBAC:

```bash
# Check if your email has cluster-admin
kubectl get clusterrolebinding -o yaml | grep your-email@gmail.com

# Test authentication
kubectl auth can-i '*' '*' --as=your-email@gmail.com
```

### OAuth2-Proxy Not Protecting Headlamp

Verify ingress annotations:

```bash
kubectl get ingress -n headlamp headlamp -o yaml
```

Look for the `auth-url` and `auth-signin` annotations.

## Testing the Setup

1. **Clear browser cookies** for `.planetlauritsen.com`
2. **Navigate to** `https://headlamp.home.planetlauritsen.com`
3. **Should redirect** to Google OAuth login
4. **After login**, should redirect back to Headlamp
5. **Headlamp should load** with full cluster access

## Next Steps

1. Apply the ingress annotation changes
2. Sync the ArgoCD application for Headlamp
3. Test authentication flow
4. Verify cluster access in Headlamp UI

## References

- [OAuth2-Proxy Documentation](https://oauth2-proxy.github.io/oauth2-proxy/)
- [Headlamp OIDC Configuration](https://headlamp.dev/docs/latest/installation/configuration/#oidc)
- [Kubernetes OIDC Authentication](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens)
- [nginx-ingress External Auth](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#external-authentication)

