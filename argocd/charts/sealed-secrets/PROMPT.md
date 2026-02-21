# Migrate Sealed Secrets to Argo CD
This is a guide to migrating Sealed Secrets from a standard installation to an Argo CD managed installation. The process involves several steps, including backing up existing Sealed Secret keypair, 
uninstall the existing Sealed Secrets controller with Helm,
restore the keypair in the cluster, and then
installing the Sealed Secrets controller using Argo CD.

## Step 1: Backup Existing Sealed Secret Keypair
Before uninstalling the existing Sealed Secrets controller, it's crucial to backup the existing keypair. You can do this by exporting the keypair secret to a YAML file:

```bash
kubectl -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-key-backup.yaml
```

## Step 2: Uninstall Existing Sealed Secrets Controller
Next, uninstall the existing Sealed Secrets controller that was installed using Helm. You can do this
by running the following command:

```bash
helm uninstall sealed-secrets -n kube-system
```

## Step 3: Restore Keypair in the Cluster
After uninstalling the existing controller, you need to restore the keypair in the cluster. You can do this by applying the backup YAML file you created in Step 1: 
```bash
kubectl apply -n kube-system -f sealed-secrets-key-backup.yaml
``` 
## Step 4: Install Sealed Secrets Controller using Argo CD
Finally, you can install the Sealed Secrets controller using Argo CD. You can do this by creating an Argo CD application that points to the Sealed Secrets chart in your repository. Make sure to specify the correct namespace and values for the installation.
Here's an example of how to create an Argo CD application for the Sealed Secrets controller:
