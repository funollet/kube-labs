# https://just.systems

kind-config := "kind-config/one-node.yaml"
default_overlay := "kind"

# show this message
help:
    @just --list --unsorted

# create a new cluster with a few extras
create name: (create-cluster name) \
    start-lb \
    (deploy "metrics-server")

# destroy the cluster
destroy name: stop-lb (destroy-cluster name)

# ensure cluster and load balancer are running
start:
  @echo "Not yet implemented"

# ensure cluster and load balancer are stopped
stop:
  @echo "Not yet implemented"

# create a new kind cluster
create-cluster name:
  kind create cluster --name {{name}} --config {{kind-config}}

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
destroy-cluster name:
  kind delete cluster --name {{name}}

# deploy an app from the manifests
deploy app:
  kustomize build manifests/{{app}}/overlays/{{default_overlay}} \
    | kubectl apply -f -
