# kubert

Simple tool to manage multiple Kubernetes contexts simultaneously in separate terminal windows/tabs.

Kubert allows you to run different kubectl contexts in different terminal tabs/windows by automatically setting `KUBECONFIG` to separate kubeconfig files. Each context gets its own isolated configuration file, preventing context-switching conflicts when working with multiple clusters.

## Prerequisites

- `yq` - YAML parser/processor
- `crudini` - INI file manipulation tool
- `fzf` - Fuzzy finder for context selection
- `aws` CLI - For AWS EKS clusters
- `kops` - Only if connecting to kOps-managed clusters
- Bash shell

## Installation

1. Clone this repository or download the scripts
2. Source the `kubert.bash` script in your shell profile (e.g., `~/.bashrc`, `~/.zshrc`):
   ```bash
   source /path/to/kubert.bash
   ```
3. Create your kubert configuration file at `~/.config/kubert.yaml` (see Configuration section below)
4. Set up your AWS config with the necessary profiles (see AWS Configuration section below)

## Configuration

### Kubert Config File

Create a configuration file at `~/.config/kubert.yaml`. See [example.kubert.yaml](example.kubert.yaml) for a complete example.

```yaml
defaults:
  short_region: ue1
  region: us-east-1

contexts:
  # EKS Clusters
  dev:
    environment: dev
    aws_profile: myaws-gbl-dev-poweruser

  staging:
    environment: staging
    aws_profile: myaws-gbl-staging-poweruser

  prod:
    environment: prod
    aws_profile: myaws-gbl-prod-poweruser

  # Multi-region example
  uw2-prod:
    environment: prod
    aws_profile: myaws-gbl-prod-poweruser
    short_region: uw2
    region: us-west-2

  # Custom cluster name
  custom:
    environment: nonprod
    aws_profile: myaws-gbl-nonprod-poweruser
    cluster: my-custom-cluster-name

  # kOps Clusters
  kops-staging:
    environment: staging
    aws_profile: myaws-gbl-staging-poweruser
    cluster: us-east-1.staging.mycompany.com
```

#### Configuration Options

- **defaults**: Default values used when not specified in a context
  - `short_region`: Short region code (e.g., `ue1` for us-east-1)
  - `region`: AWS region (e.g., `us-east-1`)

- **contexts**: Named contexts for your clusters
  - `environment`: The environment name (used in cluster naming convention)
  - `aws_profile`: AWS CLI profile to use for authentication (optional)
  - `short_region`: Override default short region code (optional)
  - `region`: Override default AWS region (optional)
  - `cluster`: Override default cluster name (optional)

### AWS Configuration

Set up AWS CLI profiles in `~/.aws/config` that correspond to the `aws_profile` values in your kubert config.

Example AWS config profiles:

```ini
[profile myaws-gbl-identity-poweruser]
region = us-east-1
# This is your base identity profile with credentials

[profile myaws-gbl-security-prod-poweruser]
region = us-east-1
source_profile = myaws-gbl-identity-poweruser
role_arn = arn:aws:iam::123456789012:role/myaws-gbl-security-prod-poweruser

[profile myaws-gbl-dev-poweruser]
region = us-east-1
source_profile = myaws-gbl-identity-poweruser
role_arn = arn:aws:iam::234567890123:role/myaws-gbl-dev-poweruser

[profile myaws-gbl-staging-poweruser]
region = us-east-1
source_profile = myaws-gbl-identity-poweruser
role_arn = arn:aws:iam::345678901234:role/myaws-gbl-staging-poweruser

[profile myaws-gbl-prod-poweruser]
region = us-east-1
source_profile = myaws-gbl-identity-poweruser
role_arn = arn:aws:iam::456789012345:role/myaws-gbl-prod-poweruser

[profile myaws-gbl-nonprod-poweruser]
region = us-east-1
source_profile = myaws-gbl-identity-poweruser
role_arn = arn:aws:iam::567890123456:role/myaws-gbl-nonprod-poweruser
```

## Usage

### Basic Usage

Run kubert with a context name:

```shell
kubert dev
```

This will:
1. Set `KUBECONFIG` to `~/.kube/dev.config.yaml` (creating it if needed)
2. Run `aws eks update-kubeconfig` to configure kubectl for the cluster
3. Set the appropriate AWS profile and region

Example output:
```
$KUBECONFIG is now /Users/username/.kube/dev.config.yaml
aws eks update-kubeconfig --name="myaws-ue1-dev-eks-cluster" --region="us-east-1" --profile="myaws-gbl-dev-poweruser"
Updated context arn:aws:eks:us-east-1:234567890123:cluster/myaws-ue1-dev-eks-cluster in /Users/username/.kube/dev.config.yaml
```

### Interactive Context Selection

Run `kubert` without arguments to get an interactive fuzzy-finder menu:

```shell
kubert
```

Use arrow keys or type to filter contexts, then press Enter to select.

### Multiple Terminal Windows/Tabs

The power of kubert is that each terminal window/tab maintains its own `KUBECONFIG`:

```shell
# Terminal 1
kubert dev
kubectl get pods  # Shows dev cluster pods

# Terminal 2
kubert prod
kubectl get pods  # Shows prod cluster pods

# Terminal 3
kubert staging
kubectl get pods  # Shows staging cluster pods
```

Each terminal maintains its own isolated kubectl context without interfering with the others.

## How It Works

Kubert creates separate kubeconfig files for each context in `~/.kube/`. When you run `kubert <context>`:

1. Reads the context configuration from `~/.config/kubert.yaml`
2. Sets `KUBECONFIG` environment variable to `~/.kube/<context>.config.yaml`
3. For EKS clusters: Runs `aws eks update-kubeconfig` with the appropriate parameters
4. For kOps clusters: Uses `kops export kubecfg` to configure kubectl

Each terminal session has its own `KUBECONFIG`, so switching contexts in one terminal doesn't affect others.

## Tips

- **iTerm2 Integration**: Create iTerm2 profiles that automatically run `kubert <context>` on launch for one-click cluster access
- **Tab Naming**: Consider using terminal tab naming to identify which cluster you're connected to
- **Shell Prompt**: Integrate your current context into your shell prompt for visual confirmation
- **Aliases**: Create shell aliases for frequently used contexts:
  ```bash
  alias kubert-dev='kubert dev'
  alias kubert-staging='kubert staging'
  alias kubert-prod='kubert prod'
  ```

## Troubleshooting

**Context not found**: Ensure the context name exists in your `~/.config/kubert.yaml`

**AWS authentication errors**: Verify your AWS profiles are correctly configured in `~/.aws/config` and you have valid credentials

**kubectl not connecting**: Check that your AWS profile has the necessary EKS permissions and that the cluster name matches your naming convention

## License

See [LICENSE](LICENSE) file for details.

