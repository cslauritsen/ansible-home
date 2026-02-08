# Safe ArgoCD Migration Strategy for Roundcube

## Current State Assessment

Before syncing with ArgoCD, check what's currently running:

```bash
# Find current roundcube deployment
kubectl get all -A | grep roundcube

# Check which namespace it's in
CURRENT_NS=$(kubectl get deploy -A -o json | jq -r '.items[] | select(.metadata.name | test("roundcube")) | .metadata.namespace' | head -1)
echo "Current namespace: $CURRENT_NS"

# Check if it has ArgoCD labels (it shouldn't from Helmfile)
kubectl get deploy -n $CURRENT_NS -o yaml | grep -A5 "labels:" | grep argocd
```

## Safe Sync Strategy

### Option 1: Clean Migration (Recommended)

**Step 1:** Prepare the PV (as documented in MIGRATION-GUIDE.md)
```bash
# Delete old PVC, patch PV to remove claimRef
kubectl delete pvc <OLD_PVC> -n $CURRENT_NS
kubectl patch pv pvc-87272075-5eec-4202-98b6-a721b73571aa -p '{"spec":{"claimRef": null}}'
```

**Step 2:** Delete old Roundcube deployment
```bash
# Since it's from Helmfile, remove it cleanly
helm uninstall roundcube -n $CURRENT_NS
# OR if it was deployed differently:
kubectl delete deploy,svc,ingress -n $CURRENT_NS -l app=roundcube
```

**Step 3:** Deploy with ArgoCD
```bash
argocd app sync roundcube
```

### Option 2: Side-by-Side Migration

If the old deployment is in a different namespace (e.g., `default`):

**Step 1:** Sync ArgoCD to create in new namespace
```bash
# This creates resources in 'roundcube' namespace
argocd app sync roundcube
```

**Step 2:** Test the new deployment
```bash
kubectl get pods -n roundcube
# Test the application works
```

**Step 3:** Clean up old deployment manually
```bash
# Old deployment in different namespace is untouched
helm uninstall roundcube -n $CURRENT_NS
```

## What ArgoCD Will Do

### First Sync (with your current config):
- ✅ Create Deployment in `roundcube` namespace
- ✅ Create Service in `roundcube` namespace  
- ✅ Create Ingress in `roundcube` namespace
- ✅ Create PVC in `roundcube` namespace (binds to existing PV)
- ❌ Will NOT touch anything in other namespaces
- ❌ Will NOT delete existing resources (no prune enabled)

### If Resources Already Exist in Target Namespace:
ArgoCD will show one of these states:
- **OutOfSync** - Resource exists but doesn't match Git
- **Sync Failed** - Resource conflict (already exists with different owner)
- You can then manually delete the old resource and re-sync

## Enabling Auto-Sync Later

Only after you've validated everything works:

```bash
# Edit the application to uncomment automated sync
kubectl edit app roundcube -n argocd

# Or update in Git:
spec:
  syncPolicy:
    automated:
      prune: true        # Only deletes resources ArgoCD created
      selfHeal: true     # Auto-sync when Git changes
```

**Even with `prune: true`:** ArgoCD only prunes resources IT created (with ArgoCD tracking labels)

## Safety Guarantees

✅ **Your Helmfile deployments are safe** - They don't have ArgoCD labels
✅ **Manual resources are safe** - They don't have ArgoCD tracking
✅ **Other namespaces are safe** - ArgoCD apps are namespace-scoped
✅ **PV is safe** - Has Retain policy, won't be deleted
✅ **Manual sync gives full control** - You see what will happen before it does

## Emergency Rollback

If something goes wrong:

```bash
# Delete the ArgoCD application (doesn't delete resources by default)
argocd app delete roundcube --cascade=false

# Or delete everything ArgoCD created
argocd app delete roundcube

# Old deployment is still there if you didn't delete it
```

