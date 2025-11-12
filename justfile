# https://just.systems

_ := require("gum")
_ := require("abduco")

# Path to Kind cluster configuration file
# Override with: KIND_CONFIG=path/to/config.yaml just <task>
# Available configs: kind-config/one-node.yaml, kind-config/three-workers.yaml
kind_config := env("KIND_CONFIG", "kind-config/one-node.yaml")

# Kustomize overlay for cluster type
# Override with: OVERLAY=<overlay> just <task>
# Available overlays: kind (default for local Kind clusters)
overlay := env("OVERLAY", "kind")


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
start: start-containers start-lb
 
# ensure cluster and load balancer are stopped
stop: stop-lb stop-containers

# start stopped Kind cluster containers
start-containers:
  #!/usr/bin/env bash
  # Get cluster name from current kubectl context
  cluster_name=$(kubectl config current-context | sed 's/kind-//')

  # Check and start Kind cluster containers
  stopped_containers=$(docker ps -a --filter "label=io.x-k8s.kind.cluster=$cluster_name" --filter "status=exited" --format '{{{{.ID}}')

  if [ -n "$stopped_containers" ]; then
    docker start $stopped_containers
  fi

# create a new kind cluster
create-cluster name:
  kind create cluster --name {{name}} --config {{kind_config}}

# run cloud-provider-kind in background
start-lb:
  -abduco -n cloud-provider-kind cloud-provider-kind

# stop cloud-provider-kind
stop-lb:
  -pkill -f "abduco.*cloud-provider-kind"

# stop Kind cluster containers
stop-containers:
  #!/usr/bin/env bash
  # Get cluster name from current kubectl context
  cluster_name=$(kubectl config current-context | sed 's/kind-//')

  # Stop all running Kind cluster containers
  running_containers=$(docker ps --filter "label=io.x-k8s.kind.cluster=$cluster_name" --filter "status=running" --format '{{{{.ID}}' )

  if [ -n "$running_containers" ]; then
    docker stop $running_containers
  fi

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
  kustomize build manifests/$app/overlays/{{overlay}} \
    | kubectl apply -f -
