#!/usr/bin/env bash

if [[ -z "$KUBERT_CONFIG_FILE" ]]; then
  KUBERT_CONFIG_FILE="${HOME}/.config/kubert.yaml"
fi

################################################################################
# Expecting $1 to be provided as the context. If not provided, an fzf option
# box will appear.
################################################################################
function kubert_context_prompt () {
  CONTEXT=$(yq '.contexts | keys | .[]' ~/.config/kubert.yaml | sort | fzf --height 50% --reverse --select-1 --prompt='-> ' --tiebreak='begin,index' --header 'Select Kubernetes context') ; echo "$CONTEXT"
}

# Switch context files
function kubeswitch () {
  CONTEXT=$1

  KUBECONFIG_FILE=~/.kube/$CONTEXT.config.yaml
  if [[ ! -f $KUBECONFIG_FILE ]] ; then
    echo "$KUBECONFIG_FILE not found. Creating it."
    touch "$KUBECONFIG_FILE"
    chmod 600 "$KUBECONFIG_FILE"
  fi
  echo "\$KUBECONFIG is now ${KUBECONFIG_FILE}"
  export KUBECONFIG=$KUBECONFIG_FILE
}

function read_kubert_defaults () {
  DEFAULT_SHORT_REGION=$(yq ".defaults.short_region" "$KUBERT_CONFIG_FILE")
  DEFAULT_REGION=$(yq ".defaults.region" "$KUBERT_CONFIG_FILE")
}

function read_kubert_context () {
  CONTEXT=$1
  CHECK_CONTEXT=$(yq ".contexts.${CONTEXT}" "$KUBERT_CONFIG_FILE")
  if [[ "$CHECK_CONTEXT" == "null" ]] ; then
    echo "💩 Context ${CONTEXT} not found."
    unset CONTEXT
  else
    environment=$(yq ".contexts.${CONTEXT}.environment" "$KUBERT_CONFIG_FILE")
    aws_profile=$(yq ".contexts.${CONTEXT}.aws_profile // \"\"" "$KUBERT_CONFIG_FILE")
    AWS_SHORT_REGION=$(yq ".contexts.${CONTEXT}.short_region // \"$DEFAULT_SHORT_REGION\"" "$KUBERT_CONFIG_FILE")
    AWS_REGION=$(yq ".contexts.${CONTEXT}.region // \"$DEFAULT_REGION\"" "$KUBERT_CONFIG_FILE")
    CLUSTER=$(yq ".contexts.${CONTEXT}.cluster // \"\"" "$KUBERT_CONFIG_FILE")
  fi
}

function kubert () {
  CONTEXT=$1

  if [[ -z "$CONTEXT" ]] ; then
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
      CLUSTER="spoton-${AWS_SHORT_REGION}-${environment}-eks-cluster"
    fi

    if [[ -z "$aws_profile" ]]; then
      aws_profile="spoton-gbl-${environment}-admin"
    fi

    if [[ "$CONTEXT" == "kops-"* ]] ; then
      assume-role "$aws_profile"
      chamber exec kops -- kops export kubecfg --admin=87600h
    else
      # echo "aws eks update-kubeconfig --name=\"$CLUSTER\" --region=\"$AWS_REGION\" --profile=\"$aws_profile\""
      kubectl config current-context 2>/dev/null || aws eks update-kubeconfig --name="$CLUSTER" --region="$AWS_REGION" --profile="$aws_profile"
    fi

    export AWS_REGION
    export AWS_SHORT_REGION
    export CLUSTER
  fi
}
