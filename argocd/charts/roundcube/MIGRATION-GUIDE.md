# Roundcube Migration to ArgoCD

## Overview
This guide explains how to migrate Roundcube from Helmfile to ArgoCD while preserving the existing Longhorn PV data.

## Prerequisites
- Existing PV: `pvc-87272075-5eec-4202-98b6-a721b73571aa`
- PV Reclaim Policy: `Retain` (already set)
- Backup: Already completed

## Migration Steps

### 1. Remove the PVC claim from the PV (without deleting data)

Before installing via ArgoCD, you need to release the PV from the old PVC:

```bash
# Get the current PVC name
OLD_PVC=$(kubectl get pvc -A -o json | jq -r '.items[] | select(.spec.volumeName=="pvc-87272075-5eec-4202-98b6-a721b73571aa") | .metadata.namespace + "/" + .metadata.name')

# Delete the old PVC (data is safe because PV has Retain policy)
kubectl delete pvc $OLD_PVC

# Verify the PV is now "Released"
kubectl get pv pvc-87272075-5eec-4202-98b6-a721b73571aa
```

### 2. Remove the claimRef from the PV to make it available

The PV will be in "Released" state. You need to remove the old claimRef to make it "Available":

```bash
kubectl patch pv pvc-87272075-5eec-4202-98b6-a721b73571aa -p '{"spec":{"claimRef": null}}'

# Verify the PV is now "Available"
kubectl get pv pvc-87272075-5eec-4202-98b6-a721b73571aa
```

### 3. Deploy via ArgoCD

The ArgoCD application is configured in `argocd/applications/roundcube.yaml` and will:
- Create a new PVC in the `roundcube` namespace
- Bind to the existing PV using `volumeName: pvc-87272075-5eec-4202-98b6-a721b73571aa`
- Preserve all your existing data

```bash
# Commit and push changes
git add charts/roundcube/ argocd/applications/roundcube.yaml
git commit -m "Migrate Roundcube to ArgoCD with existing PV"
git push

# Sync the root app to discover the new application
argocd app sync root-app

# Sync the roundcube application
argocd app sync roundcube
```

### 4. Verify the deployment

```bash
# Check that the PVC is bound to the correct PV
kubectl get pvc -n roundcube

# Verify the PV is bound
kubectl get pv pvc-87272075-5eec-4202-98b6-a721b73571aa

# Check the pod is running
kubectl get pods -n roundcube

# Verify data is accessible
kubectl exec -n roundcube -it deployment/roundcube -- ls -la /var/roundcube
```

## Rollback Plan

If something goes wrong:

1. The PV still has `Retain` policy, so data is safe
2. You can delete the ArgoCD application
3. Re-patch the PV claimRef if needed
4. Redeploy using Helmfile if necessary

## Notes

- The `volumeName` field in the PVC ensures it binds to the specific PV
- The storage size in the PVC should match or be less than the PV size
- Longhorn will maintain all your data throughout this process

