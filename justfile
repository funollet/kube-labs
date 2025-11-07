# https://just.systems

kind_config := "kind-config/one-node.yaml"
default_overlay := "kind"

# show this message
help:
    @just --list --unsorted

# create a new cluster with a few extras
create name: (create-cluster name) \
    start-lb \
    (deploy "metrics-server")

# destroy the cluster
destroy: stop-lb destroy-cluster

# ensure cluster and load balancer are running
start:
  @echo "Not yet implemented"

# ensure cluster and load balancer are stopped
stop:
  @echo "Not yet implemented"

# create a new kind cluster
create-cluster name:
  kind create cluster --name {{name}} --config {{kind_config}}

# run cloud-provider-kind in background
start-lb:
  #!/usr/bin/env bash
  cloud-provider-kind > /tmp/cloud-provider-kind.log 2>&1 &
  echo $! > /tmp/cloud-provider-kind.pid

# stop cloud-provider-kind
stop-lb:
  -kill $(cat /tmp/cloud-provider-kind.pid)
  -rm /tmp/cloud-provider-kind.pid

# destroy the cluster
destroy-cluster:
  #!/usr/bin/env bash
  cluster_name=$(kubectl config current-context | sed 's/kind-//')
  gum confirm --default=false "Delete cluster '$cluster_name'?" || exit 0
  gum confirm --default=false "Really REALLY delete cluster '$cluster_name'?" || exit 0
  kind delete cluster --name $cluster_name

# deploy an app from the manifests
deploy app="":
  #!/usr/bin/env bash
  if [ -z "{{app}}" ]; then
    app=$(ls manifests | gum filter --placeholder "Choose an app to deploy")
    [ -z "$app" ] && exit 0
  else
    app="{{app}}"
  fi
  set -x
  kustomize build manifests/$app/overlays/{{default_overlay}} \
    | kubectl apply -f -
