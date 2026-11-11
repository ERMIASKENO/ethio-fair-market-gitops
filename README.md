# ethio-fair-market-gitops

The desired state of the **ethio-fair-market** platform. Argo CD watches this repository and makes the
cluster match it. Nobody runs `kubectl apply` for application changes – you change Git, Argo CD deploys.

```
bootstrap/root-app.yaml            the only object applied by hand ("app of apps")
argocd/
  project.yaml                     AppProject efm: allowed repo, namespaces and kinds
  platform-dev.yaml                Application  -> platform/overlays/dev   (Kustomize)
  services-dev.yaml                ApplicationSet: one Application per environments/dev/services/*.yaml (Helm)
charts/microservice/               one generic Helm chart for every service
platform/
  base/                            namespaces, ResourceQuota, LimitRange, default-deny NetworkPolicy,
                                   PostgreSQL (CloudNativePG Cluster + Database per service), PodMonitor
  overlays/dev                     your home cluster
  overlays/prod                    example: HA PostgreSQL, bigger quotas (not deployed)
environments/dev/
  values-common.yaml               shared values (pull secret, hostname, JWT settings)
  services/<name>.yaml             one file per service: image tag (updated by CI), env, resources, route, network policy
```

## How a change reaches the cluster

1. A developer pushes code to `ethio-fair-market`.
2. GitHub Actions tests it, builds the image, pushes `ghcr.io/ermiaskeno/efm-<service>:<sha>`.
3. CI commits the new tag into `environments/dev/services/<service>.yaml` here.
4. Argo CD notices the commit (every ~2 minutes) and performs a rolling update.
5. Rollback = `git revert` of that commit.

## Add a new service

1. Create `environments/dev/services/<name>.yaml` (copy an existing one).
2. Commit + push. The ApplicationSet creates `efm-dev-<name>` automatically.

## What every service gets from the chart

| Object | Why |
|---|---|
| Deployment | rolling updates without downtime (`maxUnavailable: 0`), startup/liveness/readiness probes, `preStop` sleep for graceful shutdown, read-only root filesystem, non-root, all capabilities dropped, seccomp |
| Service | stable in-cluster name (`http://listings`) |
| ServiceAccount | own identity, API token not mounted |
| ConfigMap | non-secret configuration (`config:`), pods restart when it changes (checksum annotation) |
| HorizontalPodAutoscaler | scales on CPU (and memory if set) with calm scale-down |
| PodDisruptionBudget | protects against voluntary disruptions but never blocks a node drain |
| NetworkPolicy | zero trust: only listed callers in, only listed targets out (+ DNS) |
| HTTPRoute | public path on `https://efm.shop.internal` through the Envoy gateway |
| ServiceMonitor | Prometheus scrapes `/metrics` |

Secrets (database passwords, JWT signing key, registry token) are **never stored in Git**; they are created
in the cluster by `deploy-kit/2-secrets.sh`. Phase 2 replaces this with Sealed Secrets / External Secrets.
