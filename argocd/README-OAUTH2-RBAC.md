# ArgoCD with OAuth2-Proxy Authentication and RBAC

## Overview

This configuration sets up ArgoCD to work with oauth2-proxy for authentication, eliminating the need to log in twice (once for oauth2-proxy, and again for ArgoCD admin).

## How It Works

1. **nginx-ingress** intercepts requests to ArgoCD and validates authentication via oauth2-proxy
2. **oauth2-proxy** authenticates users via OAuth2/OIDC (e.g., Google, GitHub, etc.)
3. **nginx-ingress** passes authentication headers (`X-Auth-Request-User`, `X-Auth-Request-Email`) to ArgoCD
4. **ArgoCD** trusts these headers (since they come from an authenticated source) and grants permissions based on RBAC rules

## Current Configuration

### Anonymous Access Enabled

The configuration enables ArgoCD's "anonymous" access mode:

```yaml
users.anonymous.enabled: "true"
```

**Important:** Despite the name "anonymous", users are NOT anonymous - they've been authenticated by oauth2-proxy. ArgoCD just treats them as "anonymous" from its perspective since it's not doing the authentication itself.

### RBAC Configuration

There are **two approaches** you can choose from:

#### Approach 1: Grant Admin to All OAuth2-Authenticated Users (Current Default)

This is currently configured and is the **simplest approach**. If oauth2-proxy already restricts access to trusted users (via email whitelist), you can grant admin to everyone who makes it through:

```yaml
policy.csv: |
  # Grant admin permissions to all anonymous (proxy-authenticated) users
  p, role:anonymous, applications, *, */*, allow
  p, role:anonymous, clusters, get, *, allow
  p, role:anonymous, repositories, *, *, allow
  p, role:anonymous, projects, *, *, allow
  p, role:anonymous, accounts, *, *, allow
  p, role:anonymous, certificates, *, *, allow
  p, role:anonymous, gpgkeys, *, *, allow
  g, role:anonymous, role:admin
```

**Use this if:** Your oauth2-proxy `allowed-emails.txt` already contains only trusted administrators.

#### Approach 2: Grant Admin to Specific Email Addresses (More Granular)

For more fine-grained control, you can grant admin only to specific users. However, **this is more complex** because ArgoCD's RBAC doesn't directly read the email from headers when using anonymous access.

To implement this approach, you would need to:

1. Set up ArgoCD with proper OIDC/SSO integration (bypassing oauth2-proxy for ArgoCD authentication)
2. Or use a custom authentication webhook
3. Or implement a Lua script in nginx to map emails to user identities

**For most home lab scenarios, Approach 1 is recommended.**

## Configuration Files Modified

### `/helmfile/argocd/values.yaml`

Key changes:
- Added `nginx.ingress.kubernetes.io/auth-response-headers` annotation to pass authentication headers
- Enabled `users.anonymous.enabled: "true"` in ArgoCD config
- Added RBAC policy granting admin role to anonymous (proxy-authenticated) users
- Enabled RBAC logging: `server.rbac.log.enforce.enable: "true"`

## Deployment Steps

1. **Update the configuration** (already done)

2. **Apply the changes:**
   ```bash
   helmfile -f helmfile/argocd/helmfile.yaml apply
   ```

3. **Wait for pods to restart:**
   ```bash
   kubectl rollout status deployment/argocd-server -n argocd
   ```

4. **Test the access:**
   - Navigate to `https://argocd.home.planetlauritsen.com`
   - You should be redirected to oauth2-proxy for authentication
   - After authenticating, you should have full admin access without needing to log in again

## Verifying RBAC Permissions

To check if RBAC is working correctly:

1. **Check ArgoCD logs:**
   ```bash
   kubectl logs -n argocd deployment/argocd-server | grep -i rbac
   ```

2. **Test in the UI:**
   - Try creating/deleting applications
   - Try accessing Settings → Repositories
   - All admin functions should be available

3. **Check your user identity:**
   - In ArgoCD UI, click on the user icon (top right)
   - You should see your user info (may show as "anonymous" but with admin permissions)

## Customization Options

### Option 1: Restrict to Specific Emails (Granular Control)

If you want different permission levels for different users, you need to set up proper OIDC authentication. Here's how:

1. **Keep oauth2-proxy** for initial authentication
2. **Configure ArgoCD's built-in OIDC** to also authenticate with the same provider
3. **Update RBAC rules** to grant permissions based on email:

```yaml
configs:
  cm:
    url: https://argocd.home.planetlauritsen.com
    
    # Add OIDC configuration
    oidc.config: |
      name: OAuth2
      issuer: https://accounts.google.com  # or your OIDC provider
      clientID: $oidc.google.clientID
      clientSecret: $oidc.google.clientSecret
      requestedScopes: ["openid", "profile", "email"]
      
  rbac:
    policy.csv: |
      # Grant admin to specific users
      g, user1@example.com, role:admin
      g, user2@example.com, role:admin
      
      # Grant readonly to others
      p, role:readonly, applications, get, */*, allow
      p, role:readonly, clusters, get, *, allow
```

### Option 2: Give Everyone Admin (Simplest)

Current configuration. Just ensure your oauth2-proxy restricts access properly.

### Option 3: Give Everyone Readonly, Specific Users Admin

This would require proper OIDC setup (see Option 1), then:

```yaml
configs:
  rbac:
    policy.default: role:readonly
    policy.csv: |
      g, admin@example.com, role:admin
```

## Troubleshooting

### Issue: Still seeing login page after oauth2-proxy authentication

**Cause:** ArgoCD might not be recognizing anonymous users.

**Solution:**
1. Check that `users.anonymous.enabled: "true"` is set in config
2. Verify nginx is passing headers: `kubectl logs -n ingress-nginx <nginx-pod> | grep X-Auth-Request`
3. Check ArgoCD server logs: `kubectl logs -n argocd deployment/argocd-server`

### Issue: "Permission denied" errors in ArgoCD UI

**Cause:** RBAC policies not applied or incorrect.

**Solution:**
1. Verify RBAC config: `kubectl get configmap argocd-rbac-cm -n argocd -o yaml`
2. Check logs: `kubectl logs -n argocd deployment/argocd-server | grep -i rbac`
3. Ensure `policy.csv` is properly formatted (no syntax errors)

### Issue: Want to see which user is logged in

**Cause:** Anonymous access doesn't show user identity clearly.

**Solution:**
Set up proper OIDC authentication (see Option 1 above) instead of relying on anonymous access.

## Security Considerations

1. **oauth2-proxy is your security boundary** - Make sure it's properly configured with:
   - Email whitelist (`allowed-emails.txt`)
   - Or email domain restriction (`--email-domain`)
   - Strong cookie secret
   - HTTPS only

2. **Network security** - Ensure ArgoCD is only accessible through the nginx-ingress with oauth2-proxy protection

3. **Audit logging** - Enable ArgoCD audit logs if you need to track who did what:
   ```yaml
   configs:
     params:
       server.rbac.log.enforce.enable: "true"
   ```

## References

- [ArgoCD RBAC Documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/)
- [ArgoCD Anonymous Access](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#anonymous-access)
- [nginx-ingress auth annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#external-authentication)
- [oauth2-proxy documentation](https://oauth2-proxy.github.io/oauth2-proxy/)

## Summary

**Complexity: Low to Medium**

The implemented solution grants admin privileges to all users authenticated by oauth2-proxy. This is:
- ✅ Simple to set up
- ✅ No double login required
- ✅ Works well when oauth2-proxy already restricts to trusted users
- ⚠️ All authenticated users get admin (ensure oauth2-proxy is properly restricted)
- ❌ No per-user granularity (everyone gets the same permissions)

For most home lab use cases where oauth2-proxy already restricts to your email(s), this is the perfect solution!

