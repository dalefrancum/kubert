#!/usr/bin/env bash

if [[ -z "$KUBERT_CONFIG_FILE" ]]; then
  KUBERT_CONFIG_FILE="${HOME}/.config/kubert/kubert.yaml"
fi

################################################################################
# Expecting $1 to be provided as the context. If not provided, an fzf option
# box will appear.
################################################################################
function kubert_context_prompt() {
  CONTEXT=$(yq '.contexts | keys | .[]' "$KUBERT_CONFIG_FILE" | sort | fzf --height 50% --reverse --select-1 --prompt='-> ' --tiebreak='begin,index' --header 'Select Kubernetes context')
  echo "$CONTEXT"
}

# Switch context files
function kubeswitch() {
  CONTEXT=$1

  KUBECONFIG_FILE=~/.kube/$CONTEXT.config.yaml
  if [[ ! -f $KUBECONFIG_FILE ]]; then
    echo "$KUBECONFIG_FILE not found. Creating it."
    if [[ ! -d ~/.kube ]]; then
      echo "~/.kube directory not found. Creating it."
      mkdir ~/.kube
    fi
    touch "$KUBECONFIG_FILE"
    chmod 600 "$KUBECONFIG_FILE"
  fi
  echo "\$KUBECONFIG is now ${KUBECONFIG_FILE}"
  export KUBECONFIG=$KUBECONFIG_FILE
}

function read_kubert_defaults() {
  DEFAULT_REGION=$(yq ".defaults.region" "$KUBERT_CONFIG_FILE")
}

function read_kubert_context() {
  CONTEXT=$1
  CHECK_CONTEXT=$(yq ".contexts.${CONTEXT}" "$KUBERT_CONFIG_FILE")
  if [[ "$CHECK_CONTEXT" == "null" ]]; then
    echo "💩 Context ${CONTEXT} not found."
    unset CONTEXT
  else
    aws_profile=$(yq ".contexts.${CONTEXT}.aws_profile // \"\"" "$KUBERT_CONFIG_FILE")
    AWS_REGION=$(yq ".contexts.${CONTEXT}.region // \"$DEFAULT_REGION\"" "$KUBERT_CONFIG_FILE")
    CLUSTER=$(yq ".contexts.${CONTEXT}.cluster // \"\"" "$KUBERT_CONFIG_FILE")
  fi
}

function kubert() {
  CONTEXT=$1

  if [[ -z "$CONTEXT" ]]; then
    kubert_context_prompt
  fi

  if which yq >/dev/null; then
    read_kubert_defaults
    read_kubert_context "$CONTEXT"
  else
    echo "💩 yq is not installed."
    unset CONTEXT
  fi

  if [[ -n "$CONTEXT" ]]; then

    kubeswitch "$CONTEXT"

    if [[ -z "$CLUSTER" ]]; then
      echo "💩 No cluster configured for context ${CONTEXT}."
      return 1
    fi

    if [[ -z "$aws_profile" ]]; then
      echo "💩 No aws_profile configured for context ${CONTEXT}."
      return 1
    fi

    echo "aws eks update-kubeconfig --name=\"$CLUSTER\" --region=\"$AWS_REGION\" --profile=\"$aws_profile\""
    kubectl config current-context 2>/dev/null || aws eks update-kubeconfig --name="$CLUSTER" --region="$AWS_REGION" --profile="$aws_profile"

    export AWS_REGION
    export CLUSTER
  fi
}
