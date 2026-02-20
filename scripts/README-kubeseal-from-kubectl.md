# kubeseal-from-kubectl

Prompts for a secret name and namespace, builds a Kubernetes Secret with `kubectl create secret`, then pipes it to `kubeseal` using the public cert at `scripts/pub-sealed-secrets.pem`.

## Requirements

- `kubectl`
- `kubeseal`

## Usage

```sh
scripts/kubeseal-from-kubectl.sh --from-literal=password=supersecret
```

```sh
scripts/kubeseal-from-kubectl.sh --subcommand tls --cert=./tls.crt --key=./tls.key
```

The sealed secret YAML is written to stdout.

