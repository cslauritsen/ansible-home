# Roundcube ArgoCD Migration - Quick Reference

## What Was Done

### 1. **ArgoCD Application Created**
   - File: `argocd/applications/roundcube.yaml`
   - Deploys Roundcube chart from `charts/roundcube/chart`
   - Uses values from `charts/roundcube/values-rpi.yaml`
   - Deploys to namespace: `roundcube`

### 2. **Chart Updated**
   - File: `charts/roundcube/chart/templates/pvc.yaml`
   - Added support for `volumeName` to bind to existing PV

### 3. **Values Updated**
   - File: `charts/roundcube/values-rpi.yaml`
   - Added: `volumeName: pvc-87272075-5eec-4202-98b6-a721b73571aa`

## How to Migrate (Before ArgoCD Deploy)

### Step 1: Release the PV from old PVC
```bash
# Find and delete the old PVC
kubectl get pvc -A | grep roundcube
kubectl delete pvc <OLD_PVC_NAME> -n <OLD_NAMESPACE>
```

### Step 2: Make the PV available for rebinding
```bash
# Remove the old claimRef
kubectl patch pv pvc-87272075-5eec-4202-98b6-a721b73571aa -p '{"spec":{"claimRef": null}}'

# Verify status is "Available"
kubectl get pv pvc-87272075-5eec-4202-98b6-a721b73571aa
```

### Step 3: Deploy via ArgoCD
```bash
# Commit and push
git add argocd/applications/roundcube.yaml charts/roundcube/
git commit -m "Migrate Roundcube to ArgoCD"
git push

# Sync root app
argocd app sync root-app

# Sync roundcube
argocd app sync roundcube
```

### Step 4: Verify
```bash
# Check PVC bound to correct PV
kubectl get pvc -n roundcube
kubectl get pv pvc-87272075-5eec-4202-98b6-a721b73571aa

# Check pod is running
kubectl get pods -n roundcube
```

## Key Points

✅ **PV has Retain policy** - Your data is safe during this process
✅ **volumeName binding** - The new PVC will specifically bind to your existing PV
✅ **Same storage class** - Using Longhorn as before
✅ **All data preserved** - No data migration needed

## Detailed Guide

See `charts/roundcube/MIGRATION-GUIDE.md` for complete step-by-step instructions.

