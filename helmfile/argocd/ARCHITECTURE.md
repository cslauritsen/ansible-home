# ArgoCD Application Architecture

## App-of-Apps Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                         ArgoCD Server                        │
│                      (argocd namespace)                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ watches
                              ▼
                    ┌──────────────────┐
                    │    root-app      │
                    │  (Application)   │
                    └──────────────────┘
                              │
                              │ watches Git path:
                              │ helmfile/argocd/applications/
                              │
                              ▼
        ┌─────────────────────────────────────────────┐
        │         applications/ directory              │
        │  (Contains 12 Application manifests)         │
        └───────────────────────────��─────────────────┘
                              │
                              │ spawns
                              ▼
    ┌───────────────────────────────────────────────────────┐
    │                                                       │
┌───┴───┐  ┌────────┐  ┌──────┐  ┌─────────┐  ┌─────────┐│
│metallb│  │cert-mgr│  │nginx │  │longhorn │  │sealed-  ││
│       │  │        │  │ingress│ │         │  │secrets  ││
└───┬───┘  └───┬────┘  └───┬──┘  └────┬────┘  └────┬────┘│
    │          │           │          │            │     │
    │          │           │          │            │     │
┌───┴───┐  ┌───┴────┐  ┌───┴──┐  ┌────┴────┐  ┌────┴────┐│
│oauth2-│  │grafana │  │alloy │  │k8s-dash │  │mongodb  ││
│proxy  │  │        │  │      │  │         │  │         ││
└───────┘  └────────┘  └──────┘  └─────────┘  └─────────┘│
                                                           │
┌────────┐  ┌────────┐                                     │
│rabbitmq│  │kafka   │                                     │
│        │  │        │                                     │
└────────┘  └────────┘                                     │
└───────────────────────────────────────────────────────────┘
                              │
                              │ each Application points to:
                              │ helmfile/<app>/helmfile.yaml
                              │
                              ▼
                    ┌──────────────────┐
                    │   GitHub Repo    │
                    │  ansible-home    │
                    └──────────────────┘
                              │
                              │ Helmfile plugin renders
                              ▼
                    ┌──────────────────┐
                    │  Kubernetes      │
                    │  Resources       │
                    │  (Deployed)      │
                    └──────────────────┘
```

## Data Flow

### 1. Initial Deployment
```
kubectl apply root-app.yaml
    → ArgoCD creates root-app Application
    → root-app watches applications/ directory in Git
    → ArgoCD creates 12 child Applications
    → Child apps appear in ArgoCD UI (OutOfSync)
```

### 2. Syncing an Application
```
User clicks "Sync" on metallb Application
    → ArgoCD clones Git repo
    → Helmfile plugin processes helmfile/metallb/helmfile.yaml
    → Helmfile renders Helm charts
    → ArgoCD applies rendered manifests to cluster
    → Pods/Services/etc created in metallb-system namespace
    → Application status: Synced + Healthy
```

### 3. GitOps Workflow (After Enabling Auto-Sync)
```
Developer commits change to helmfile/grafana/values.yaml
    → Push to GitHub
    → ArgoCD polls repo (every 3 min by default)
    → Detects grafana Application is OutOfSync
    → Auto-sync triggers (if enabled)
    → Helmfile re-renders chart
    → ArgoCD applies changes
    → Grafana pods restart with new config
```

## Dependency Order

```
Phase 1: Foundation
┌──────────────┐
│sealed-secrets│ ◄── Must deploy first (secrets for others)
└──────────────┘

Phase 2: Networking & Storage
┌────────┐      ┌────────────┐      ┌─────────┐
│metallb │ ───► │cert-manager│ ───► │longhorn │
└────────┘      └────────────┘      └─────────┘
                       │
                       ▼
                ┌─────────────┐
                │ingress-nginx│
                └─────────────┘
                       │
                       ▼
                ┌─────────────┐
                │oauth2-proxy │
                └─────────────┘

Phase 3: Applications (no dependencies)
┌────────┐  ┌────────────────┐  ┌───────┐  ┌────────┐
│grafana │  │kubernetes-dash │  │alloy  │  │mongodb │
└────────┘  └────────────────┘  └───────┘  └────────┘

┌────────┐  ┌────────┐
│rabbitmq│  │kafka   │
└────────┘  └────────┘
```

## Repository Structure

```
ansible-home/
├── helmfile/
│   ├── argocd/
│   │   ├── app-of-apps/
│   │   │   └── root-app.yaml          ◄── Deploy this first
│   │   ├── applications/
│   │   │   ├── metallb.yaml           ◄── ArgoCD reads these
│   │   │   ├── cert-manager.yaml
│   │   │   └── ...
│   │   └── helmfile.yaml              ◄── ArgoCD itself
│   ├── metallb/
│   │   └── helmfile.yaml              ◄── metallb app points here
│   ├── cert-manager/
│   │   └── helmfile.yaml              ◄── cert-manager app points here
│   └── ...
```

## Sync Strategies

### Manual Sync (Current)
```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true
  # automated: commented out
```
- Developer must click "Sync" in UI or run `argocd app sync`
- Safe for initial deployment
- Good for testing

### Automated Sync (Future)
```yaml
syncPolicy:
  automated:
    prune: true      # Delete resources removed from Git
    selfHeal: true   # Revert manual kubectl changes
  syncOptions:
    - CreateNamespace=true
```
- Changes in Git auto-deploy within 3 minutes
- True GitOps workflow
- Requires confidence in your manifests

## Key Concepts

### Finalizers
```yaml
finalizers:
  - resources-finalizer.argocd.argoproj.io
```
Ensures when you delete an Application, ArgoCD also deletes the deployed resources.

### Helmfile Plugin
```yaml
plugin:
  name: helmfile
```
Tells ArgoCD to use helmfile to render the manifests instead of native Helm.

### CreateNamespace
```yaml
syncOptions:
  - CreateNamespace=true
```
ArgoCD automatically creates the target namespace if it doesn't exist.

### Health Status
- **Synced**: Git matches cluster state
- **OutOfSync**: Git has changes not yet applied
- **Healthy**: All pods/services running correctly
- **Progressing**: Deployment in progress
- **Degraded**: Some resources failing
- **Suspended**: Application paused

## Troubleshooting Flow

```
Application shows "OutOfSync"
    │
    ├─► Expected: You made changes in Git
    │       → Click "Sync" to apply
    │
    └─► Unexpected: Manual kubectl changes
            → Either: Revert manual changes
            → Or: Update Git to match
            → Then: Sync

Application shows "Degraded"
    │
    └─► Check pod status: kubectl get pods -n <namespace>
            │
            ├─► ImagePullBackOff: Check image name/tag
            ├─► CrashLoopBackOff: Check logs
            ├─► Pending: Check PVC/storage/node resources
            └─► Error: Check ConfigMap/Secret references
```

## Next Steps

1. ✅ Phase 4 Complete - Applications defined
2. 🔄 Phase 5 - Convert secrets to sealed secrets
3. 🚀 Phase 6 - Deploy root-app and sync applications
4. 🎯 Phase 7 - Enable automated sync for stable apps
5. 📚 Phase 8 - Document and train team

