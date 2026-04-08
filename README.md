# kubert

Shell function for managing multiple AWS EKS Kubernetes contexts in separate terminal windows. Each terminal gets its own `KUBECONFIG` file, so switching contexts in one window never interferes with another.

## Prerequisites

- [AWS CLI](https://aws.amazon.com/cli/) with profiles configured (see [AWS Profiles](#aws-profiles) below)
- [yq](https://github.com/mikefarah/yq) - YAML processor
- [fzf](https://github.com/junegunn/fzf) - fuzzy finder for interactive context selection
- `kubectl`

## Installation

1. Create the config directory:
   ```bash
   mkdir -p ~/.config/kubert
   ```

2. Copy the shell function and example config:
   ```bash
   cp src/kubert.bash ~/.config/kubert/
   cp config/example.kubert.yaml ~/.config/kubert/kubert.yaml
   ```

3. Edit `~/.config/kubert/kubert.yaml` with your clusters and AWS profiles.

4. Source `kubert.bash` in your shell profile (`~/.zshrc` or `~/.bashrc`):
   ```bash
   source ~/.config/kubert/kubert.bash
   ```

5. Restart your shell or `source` your profile.

## Configuration

Edit `~/.config/kubert/kubert.yaml`:

```yaml
defaults:
  region: us-east-1

contexts:
  dev:
    cluster: my-dev-cluster
    aws_profile: dev-admin
  prod:
    cluster: my-prod-cluster
    region: us-east-2
    aws_profile: prod-admin
```

Each context requires:
- `cluster` - the EKS cluster name
- `aws_profile` - an AWS CLI profile name from `~/.aws/config`

Optional:
- `region` - overrides the default region for this context

The config file path defaults to `~/.config/kubert.yaml`. Override it by setting `KUBERT_CONFIG_FILE` before sourcing kubert.bash.

## AWS Profiles

Kubert depends on having AWS CLI profiles already configured in `~/.aws/config`. Each `aws_profile` value in your kubert config must correspond to a working profile. Kubert does not handle AWS authentication itself — it passes the profile to `aws eks update-kubeconfig`.

Example using AWS SSO:

```ini
[sso-session my-org]
sso_start_url = https://my-org.awsapps.com/start
sso_region = us-east-1

[profile dev-admin]
sso_session = my-org
sso_account_id = 123456789012
sso_role_name = AdministratorAccess
region = us-east-1

[profile prod-admin]
sso_session = my-org
sso_account_id = 987654321098
sso_role_name = AdministratorAccess
region = us-east-1
```

Example using IAM role assumption:

```ini
[profile identity]
region = us-east-1

[profile dev-admin]
source_profile = identity
role_arn = arn:aws:iam::123456789012:role/dev-admin
region = us-east-1
```

## Usage

Switch to a context:

```bash
kubert dev
```

This sets `KUBECONFIG` to `~/.kube/dev.config.yaml`, then runs `aws eks update-kubeconfig` with the cluster, region, and profile from your config.

Run without arguments for interactive selection via fzf:

```bash
kubert
```

### Multiple terminals

```bash
# Terminal 1
kubert dev
kubectl get pods    # dev cluster

# Terminal 2
kubert prod
kubectl get pods    # prod cluster
```

Each terminal maintains its own isolated context.

## License

See [LICENSE](LICENSE).
