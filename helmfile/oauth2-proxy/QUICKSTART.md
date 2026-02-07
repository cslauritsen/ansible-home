# OAuth2-Proxy Migration - Quick Start

## TL;DR

Moving oauth2-proxy from `longhorn-system` to its own `oauth2-proxy` namespace with proper certificates.

## One-Command Deploy

```bash
helmfile -f helmfile/oauth2-proxy/helmfile.yaml apply
```

## Verify It Works

```bash
# 1. Check deployment
kubectl get pods -n oauth2-proxy

# 2. Check certificate (should say READY = True)
kubectl get certificate -n oauth2-proxy

# 3. Test in browser (should show valid cert, no warning)
open https://oauth2-proxy.home.planetlauritsen.com

# 4. Test with Longhorn
open https://longhorn.home.planetlauritsen.com

# 5. Test with ArgoCD
open https://argocd.home.planetlauritsen.com
```

## What Changed

| Item | Before | After |
|------|--------|-------|
| Namespace | `longhorn-system` | `oauth2-proxy` |
| Certificate | Self-signed (browser warning) | cert-manager + Let's Encrypt |
| Secret Name | `wildcard-home-planetlauritsen-tls` | `oauth2-proxy-tls` |
| Config Location | `longhorn-system` | `oauth2-proxy` |

## Does It Work With Longhorn?

**Yes!** OAuth2-proxy works across namespaces because:
- Applications reference it by **public URL**: `https://oauth2-proxy.home.planetlauritsen.com`
- Not by internal service name
- Longhorn ingress doesn't need any changes

## Cleanup Old Deployment (After Testing)

```bash
# Only run this after confirming everything works!
kubectl delete deployment oauth2-proxy -n longhorn-system --ignore-not-found
kubectl delete service oauth2-proxy -n longhorn-system --ignore-not-found
kubectl delete configmap allowed-emails -n longhorn-system --ignore-not-found
```

## Troubleshooting

### Certificate not ready?
```bash
kubectl describe certificate oauth2-proxy-tls -n oauth2-proxy
```

### Still see old cert?
- Clear browser cache
- Try incognito mode
- Wait 1-2 minutes for DNS propagation

### 502 Bad Gateway?
```bash
kubectl logs -n oauth2-proxy deployment/oauth2-proxy
```

## Full Documentation

See `MIGRATION-GUIDE.md` for complete details.

