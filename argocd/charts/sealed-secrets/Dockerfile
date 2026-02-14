ARG BASE_VERSION=0.27.2
FROM docker.io/bitnami/sealed-secrets-controller:${BASE_VERSION} AS base

FROM scratch
COPY --from=base / /
COPY README.md /README.md