# OAuth2-Proxy Namespace Migration Guide

## Overview

This guide covers migrating oauth2-proxy from the `longhorn-system` namespace to its own `oauth2-proxy` namespace, while fixing certificate issues and maintaining compatibility with all existing applications (Longhorn, ArgoCD, etc.).

## What Changed

### 1. Namespace Migration
- **Old:** `longhorn-system` namespace
- **New:** `oauth2-proxy` namespace (dedicated)

### 2. Certificate Configuration
- **Old:** Self-signed certificate (causing browser warnings)
- **New:** Proper cert-manager certificate using Let's Encrypt DNS challenge
- **Secret Name:** `oauth2-proxy-tls` (managed by cert-manager)

### 3. ConfigMap Location
- **Old:** `allowed-emails` ConfigMap in `longhorn-system`
- **New:** `allowed-emails` ConfigMap in `oauth2-proxy`

## Files Modified

1. `/helmfile/oauth2-proxy/helmfile.yaml`
   - Changed namespace from `longhorn-system` to `oauth2-proxy`
   - Updated ingress configuration to use cert-manager
   - Added cert-manager.io/cluster-issuer annotation

2. `/helmfile/oauth2-proxy/rsrc/allowed-emails.yaml`
   - Updated namespace from `longhorn-system` to `oauth2-proxy`

## Why This Works Across Namespaces

OAuth2-proxy works via **nginx-ingress external authentication**, which means:

1. User requests `longhorn.home.planetlauritsen.com`
2. nginx-ingress makes a subrequest to `oauth2-proxy.home.planetlauritsen.com/oauth2/auth`
3. OAuth2-proxy (in `oauth2-proxy` namespace) validates the session cookie
4. If valid, nginx-ingress allows access to Longhorn (in `longhorn-system` namespace)

**The key:** Ingress annotations reference oauth2-proxy by its **public URL**, not by namespace/service name.

## Migration Steps

### Step 1: Deploy OAuth2-Proxy to New Namespace

```bash
# Deploy oauth2-proxy in the new namespace
helmfile -f helmfile/oauth2-proxy/helmfile.yaml apply

# Wait for deployment
kubectl rollout status deployment/oauth2-proxy -n oauth2-proxy
```

### Step 2: Verify Certificate

```bash
# Check that cert-manager created the certificate
kubectl get certificate -n oauth2-proxy

# Expected output:
# NAME                READY   SECRET              AGE
# oauth2-proxy-tls    True    oauth2-proxy-tls    1m

# Check the secret
kubectl get secret oauth2-proxy-tls -n oauth2-proxy
```

### Step 3: Test OAuth2-Proxy

```bash
# Test the oauth2-proxy endpoint directly
curl -I https://oauth2-proxy.home.planetlauritsen.com/oauth2/auth

# Should return 401 or 403 (not authenticated yet)
# Should NOT show certificate error
```

### Step 4: Verify Applications Still Work

Test each application that uses oauth2-proxy:

**Longhorn:**
```bash
open https://longhorn.home.planetlauritsen.com
```

**ArgoCD:**
```bash
open https://argocd.home.planetlauritsen.com
```

Both should:
1. Redirect to oauth2-proxy for authentication
2. Show valid certificate (no browser warning)
3. After Google authentication, redirect back to the app

### Step 5: Clean Up Old Deployment (Optional)

Once everything works, remove the old oauth2-proxy from longhorn-system:

```bash
# Check if oauth2-proxy still exists in longhorn-system
kubectl get deployment oauth2-proxy -n longhorn-system

# If it exists and everything is working in the new namespace, remove it
kubectl delete deployment oauth2-proxy -n longhorn-system
kubectl delete service oauth2-proxy -n longhorn-system
kubectl delete configmap allowed-emails -n longhorn-system
```

## Troubleshooting

### Issue: Certificate Not Generated

**Check cert-manager logs:**
```bash
kubectl logs -n cert-manager deployment/cert-manager
```

**Check certificate status:**
```bash
kubectl describe certificate oauth2-proxy-tls -n oauth2-proxy
```

**Common cause:** DNS challenge not working. Verify your cluster-issuer:
```bash
kubectl get clusterissuer letsencrypt-dns -o yaml
```

### Issue: Applications Can't Reach OAuth2-Proxy

**Symptom:** "502 Bad Gateway" or "Authentication failed"

**Solution:** Verify the oauth2-proxy service is accessible:
```bash
# Check service
kubectl get svc oauth2-proxy -n oauth2-proxy

# Test from within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -I http://oauth2-proxy.oauth2-proxy.svc.cluster.local/oauth2/auth
```

If this fails, the issue is service-level, not namespace-related.

### Issue: "Invalid Cookie Domain"

**Symptom:** Authentication succeeds but redirects fail

**Check:** Verify cookie domain settings in helmfile:
```yaml
- --cookie-domain=.planetlauritsen.com
- --whitelist-domain=*.home.planetlauritsen.com
```

These should match your domain structure.

### Issue: Still Seeing Certificate Errors

**Possible causes:**

1. **Old certificate cached in browser:**
   - Clear browser cache
   - Try incognito/private mode
   - Try different browser

2. **Certificate not ready yet:**
   ```bash
   kubectl get certificate oauth2-proxy-tls -n oauth2-proxy -w
   # Wait for READY = True
   ```

3. **Ingress using wrong certificate:**
   ```bash
   kubectl describe ingress oauth2-proxy -n oauth2-proxy
   # Check TLS section points to oauth2-proxy-tls
   ```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │  nginx-ingress  │
              │   (all namespaces)
              └────┬─────────┬──┘
                   │         │
        ┌──────────┘         └──────────┐
        │                                │
        ▼                                ▼
┌──────────────────┐          ┌─────────────────────┐
│ oauth2-proxy     │          │ Longhorn            │
│ Namespace:       │◄─────────│ Namespace:          │
│  oauth2-proxy    │  auth    │  longhorn-system    │
│                  │  check   │                     │
│ Components:      │          │ Ingress annotation: │
│ - Deployment     │          │  auth-url: https:// │
│ - Service        │          │   oauth2-proxy...   │
│ - Ingress        │          └─────────────────────┘
│ - Certificate    │
│ - ConfigMap      │          ┌─────────────────────┐
│   (emails)       │          │ ArgoCD              │
└──────────────────┘          │ Namespace: argocd   │
                              │                     │
                              │ Ingress annotation: │
                              │  auth-url: https:// │
                              │   oauth2-proxy...   │
                              └─────────────────────┘
```

## Benefits of This Setup

✅ **Namespace Isolation:** OAuth2-proxy has its own namespace, following best practices

✅ **Proper Certificates:** No more browser warnings, cert-manager handles renewal automatically

✅ **Reusability:** Easy to add oauth2-proxy authentication to any new application

✅ **Single Authentication:** One login session works for all protected applications

✅ **Maintainability:** Central configuration in one namespace

## Adding OAuth2-Proxy to New Applications

To protect a new application with oauth2-proxy, just add these annotations to its ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  namespace: my-app-namespace
  annotations:
    # Add these two lines:
    nginx.ingress.kubernetes.io/auth-url: "https://oauth2-proxy.home.planetlauritsen.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth2-proxy.home.planetlauritsen.com/oauth2/start?rd=https://$host$request_uri"
spec:
  # ... rest of ingress config
```

That's it! The app is now protected by oauth2-proxy.

## Security Considerations

1. **Email Whitelist:** Only emails in `/helmfile/oauth2-proxy/rsrc/allowed-emails.yaml` can authenticate

2. **Cookie Security:** 
   - `--cookie-secure=true` ensures cookies only sent over HTTPS
   - `--cookie-samesite=lax` prevents CSRF attacks

3. **Domain Restrictions:**
   - `--whitelist-domain` limits which domains can use this oauth2-proxy
   - `--cookie-domain` ensures cookies work across subdomains

4. **Access Token:** `--pass-access-token=true` allows applications to verify user identity

## References

- [OAuth2-Proxy Documentation](https://oauth2-proxy.github.io/oauth2-proxy/)
- [nginx-ingress External Auth](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#external-authentication)
- [cert-manager Documentation](https://cert-manager.io/docs/)

## Summary

This migration moves oauth2-proxy to its own namespace with proper cert-manager integration, eliminating certificate errors while maintaining full compatibility with Longhorn and all other applications. The authentication works across namespaces because nginx-ingress uses the public HTTPS URL for auth checks.

