# OAuth2-Proxy Configuration Changes

## Summary of Changes

This document shows exactly what was changed to migrate oauth2-proxy from `longhorn-system` to its own namespace with proper certificates.

---

## File 1: `/helmfile/oauth2-proxy/helmfile.yaml`

### Change 1: Namespace Migration (Line 7)
```diff
   - name: oauth2-proxy-config
     kubeContext: rpi
     chart: ./rsrc
-    namespace: longhorn-system
+    namespace: oauth2-proxy
```

### Change 2: Namespace Migration (Line 12)
```diff
   - name: oauth2-proxy
     kubeContext: rpi
     chart: bitnami/oauth2-proxy
     version: 6.2.11
-    namespace: longhorn-system
+    namespace: oauth2-proxy
+    createNamespace: true
```

### Change 3: Certificate Configuration (Lines 46-57)
```diff
       - ingress:
           enabled: true
           tls: true
-          selfSigned: true
+          selfSigned: false
           hostname: oauth2-proxy.home.planetlauritsen.com
           ingressClassName: nginx
-          existingSecretName: wildcard-home-planetlauritsen-tls
+          annotations:
+            cert-manager.io/cluster-issuer: letsencrypt-dns
+          extraTls:
+            - hosts:
+                - oauth2-proxy.home.planetlauritsen.com
+              secretName: oauth2-proxy-tls
```

**Why this matters:**
- ❌ Old: `selfSigned: true` → Browser warnings, not trusted
- ✅ New: `cert-manager.io/cluster-issuer` → Real Let's Encrypt certificate, auto-renewed

---

## File 2: `/helmfile/oauth2-proxy/rsrc/allowed-emails.yaml`

### Change: ConfigMap Namespace (Line 8)
```diff
 apiVersion: v1
 data:
   allowed-emails.txt: |-
     csl4jc@gmail.com
 kind: ConfigMap
 metadata:
   name: allowed-emails
-  namespace: longhorn-system
+  namespace: oauth2-proxy
```

**Why this matters:**
- ConfigMap must be in the same namespace as the deployment that uses it
- oauth2-proxy deployment is now in `oauth2-proxy` namespace

---

## Files NOT Changed (No Changes Needed!)

### `/helmfile/longhorn/ingress/longhorn-ingress.yaml`
**No changes needed** because Longhorn references oauth2-proxy by public URL:
```yaml
nginx.ingress.kubernetes.io/auth-url: "https://oauth2-proxy.home.planetlauritsen.com/oauth2/auth"
nginx.ingress.kubernetes.io/auth-signin: "https://oauth2-proxy.home.planetlauritsen.com/oauth2/start?rd=https://$host$request_uri"
```

This URL-based reference works regardless of namespace.

### `/helmfile/argocd/values.yaml`
**No changes needed** for the same reason - references by URL:
```yaml
nginx.ingress.kubernetes.io/auth-url: "https://oauth2-proxy.home.planetlauritsen.com/oauth2/auth"
```

---

## Configuration Details

### Certificate Setup

**Before:**
```yaml
ingress:
  selfSigned: true
  existingSecretName: wildcard-home-planetlauritsen-tls
```
- Uses wildcard certificate (shared with other services)
- Self-signed = browser warnings

**After:**
```yaml
ingress:
  selfSigned: false
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-dns
  extraTls:
    - hosts:
        - oauth2-proxy.home.planetlauritsen.com
      secretName: oauth2-proxy-tls
```
- Dedicated certificate for oauth2-proxy
- cert-manager automatically requests from Let's Encrypt
- Uses DNS challenge (letsencrypt-dns issuer)
- Auto-renewed every 90 days

---

## What Cert-Manager Will Do

When you deploy, cert-manager will automatically:

1. **See the annotation:** `cert-manager.io/cluster-issuer: letsencrypt-dns`
2. **Create a Certificate resource:**
   ```yaml
   apiVersion: cert-manager.io/v1
   kind: Certificate
   metadata:
     name: oauth2-proxy-tls
     namespace: oauth2-proxy
   spec:
     secretName: oauth2-proxy-tls
     dnsNames:
       - oauth2-proxy.home.planetlauritsen.com
     issuerRef:
       name: letsencrypt-dns
       kind: ClusterIssuer
   ```
3. **Request certificate from Let's Encrypt**
4. **Perform DNS-01 challenge** (via your DNS provider)
5. **Store certificate in secret:** `oauth2-proxy-tls`
6. **Ingress uses the secret** for TLS

---

## Verification Commands

### Check the changes were applied:
```bash
# Verify namespace
kubectl get deployment oauth2-proxy -n oauth2-proxy

# Verify certificate
kubectl get certificate oauth2-proxy-tls -n oauth2-proxy

# Verify ingress
kubectl get ingress oauth2-proxy -n oauth2-proxy -o yaml | grep -A5 tls
```

### Expected outputs:

**Deployment:**
```
NAME            READY   UP-TO-DATE   AVAILABLE   AGE
oauth2-proxy    1/1     1            1           5m
```

**Certificate:**
```
NAME                READY   SECRET              AGE
oauth2-proxy-tls    True    oauth2-proxy-tls    5m
```

**Ingress TLS section:**
```yaml
tls:
  - hosts:
    - oauth2-proxy.home.planetlauritsen.com
    secretName: oauth2-proxy-tls
```

---

## Line-by-Line Summary

| File | Lines | Change | Impact |
|------|-------|--------|--------|
| `helmfile.yaml` | 7 | Namespace: `longhorn-system` → `oauth2-proxy` | Isolates config |
| `helmfile.yaml` | 12-13 | Namespace + `createNamespace: true` | Isolates deployment |
| `helmfile.yaml` | 48 | `selfSigned: true` → `false` | Enables cert-manager |
| `helmfile.yaml` | 52-57 | Add cert-manager annotation + extraTls | Requests real cert |
| `allowed-emails.yaml` | 8 | Namespace: `longhorn-system` → `oauth2-proxy` | Follows deployment |

**Total:** 2 files modified, 5 specific changes

---

## Rollback Plan (If Needed)

If something goes wrong and you need to rollback:

```bash
# Option 1: Restore from git
git checkout HEAD -- helmfile/oauth2-proxy/helmfile.yaml
git checkout HEAD -- helmfile/oauth2-proxy/rsrc/allowed-emails.yaml

# Then redeploy old version
helmfile -f helmfile/oauth2-proxy/helmfile.yaml apply

# Option 2: Quick fix - change namespace back in YAML
# Edit both files, change oauth2-proxy → longhorn-system
# Then redeploy
```

However, rollback shouldn't be needed because:
- Longhorn and ArgoCD reference oauth2-proxy by URL (namespace-independent)
- The new configuration is strictly better (real certificates)
- No breaking changes in the configuration

---

## Testing Checklist

After deploying, verify each item:

- [ ] oauth2-proxy pod running in oauth2-proxy namespace
- [ ] Certificate `oauth2-proxy-tls` shows READY=True
- [ ] `https://oauth2-proxy.home.planetlauritsen.com` shows valid cert (no browser warning)
- [ ] `https://longhorn.home.planetlauritsen.com` redirects to oauth2-proxy
- [ ] After Google auth, redirects back to Longhorn successfully
- [ ] `https://argocd.home.planetlauritsen.com` works with oauth2-proxy
- [ ] Can access ArgoCD UI with admin permissions (from previous config)

All checkmarks = successful migration! 🎉

