# Roundcube SMTP Authentication Fix

## Problem

Roundcube was unable to send emails through the James mail server, showing this error:

```
PHP Error: SMTP server does not support authentication
SMTP Error: Authentication failure: james-844b6684d5-fvtnm Hello mail.home.planetlauritsen.com [10.42.x.x])
PIPELINING
ENHANCEDSTATUSCODES
8BITMIME
```

## Root Cause

The James mail server has multiple SMTP configurations:

1. **Port 25 (smtpserver-global)**: For internal/authorized clients (10.* IPs)
   - `<announce>never</announce>` - Never announces AUTH capability
   - `<authorizedAddresses>10.*</authorizedAddresses>` - Allows connections from 10.* without authentication
   - No TLS/authentication required

2. **Port 587 (smtpserver-authenticated)**: For external/authenticated clients
   - `<announce>forUnauthorizedAddresses</announce>` - Only announces AUTH to non-10.* IPs
   - Requires STARTTLS and authentication

Since Roundcube pods run with IPs in the 10.42.x.x range, they are considered "authorized" by James and AUTH is not announced. However, Roundcube's default behavior is to always attempt SMTP authentication using the user's IMAP credentials.

## Solution

Two changes were made:

### 1. Changed SMTP Port (values-rpi.yaml)

```yaml
env:
  ROUNDCUBEMAIL_SMTP_PORT: "25"  # Changed from "587"
```

Port 25 is designed for internal mail submission and doesn't require authentication for authorized IPs.

### 2. Disabled SMTP Authentication (chart/templates/config.yaml)

Added a custom Roundcube configuration to explicitly disable SMTP authentication:

```php
<?php
// Custom Roundcube configuration
// Disable SMTP authentication - use anonymous relay to internal mail server
$config['smtp_user'] = '';
$config['smtp_pass'] = '';
?>
```

This configuration is mounted at `/var/roundcube/config/config.inc.php` in the deployment.

### 3. Updated Deployment (chart/templates/deployment.yaml)

Added the volume mount for the custom config:

```yaml
- name: conf-vol
  mountPath: /var/roundcube/config/config.inc.php
  subPath: config.inc.php
```

## Deployment

To apply these changes:

1. If using ArgoCD: Sync the roundcube application
2. If using Helm directly:
   ```bash
   helm upgrade roundcube ./argocd/charts/roundcube/chart -f ./argocd/charts/roundcube/values-rpi.yaml -n roundcube
   ```

## Verification

After deployment, check the Roundcube logs:
```bash
kubectl logs -n roundcube deployment/roundcube -f
```

Try sending an email through the Roundcube webmail interface. The email should be successfully submitted to James without authentication errors.

## Security Considerations

This configuration is appropriate for internal cluster communication where:
- Roundcube and James are both in the same trusted Kubernetes cluster
- James is configured to only allow relay from specific IP ranges (10.*)
- Users still authenticate to Roundcube via IMAP for reading/managing emails
- The SMTP submission is on behalf of authenticated users

This is similar to how many traditional mail server setups work where the webmail interface has direct access to the internal SMTP relay.

