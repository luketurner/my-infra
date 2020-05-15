#!/usr/bin/env bash
# Usage: use_cluster.sh [hostname]
# where hostname is one of the hosts in the cluster (e.g. "pi1")
# Will create a kubeconfig for you based on $KUBECONFIG
# If you already have one, it will upadte the values in place.
# This is a janky script, it _does not_ work with any possible kubeconfig.
# If you have a custom one, you need to create a cluster/user/context for the script to populate.

set -e
readonly CLUSTER_HOST="${1:?must specify hostname}"

readonly CONFIG="${KUBECONFIG:=~/.kube/config}"
readonly CLUSTER_NAME="pi"
readonly USER_NAME="pi-admin"
readonly CONTEXT_NAME="pi"
readonly SERVER="https://$CLUSTER_HOST:6443"

readonly CA="$(ssh "$CLUSTER_HOST" "sudo yq read /etc/rancher/k3s/k3s.yaml 'clusters[0].cluster.certificate-authority-data'")"
readonly USER="$(ssh "$CLUSTER_HOST" "sudo yq read /etc/rancher/k3s/k3s.yaml 'users[0].user.username'")"
readonly PASS="$(ssh "$CLUSTER_HOST" "sudo yq read /etc/rancher/k3s/k3s.yaml 'users[0].user.password'")"

if [ -e "$CONFIG" ]; then

  yq write -i "$CONFIG" "clusters(name==$CLUSTER_NAME).cluster.certificate-authority-data" "$CA"
  yq write -i "$CONFIG" "users(name==$USER_NAME).user.username" "$USER"
  yq write -i "$CONFIG" "users(name==$USER_NAME).user.password" "$PASS"

else
  mkdir -p "$(dirname $CONFIG)"
  cat >> "$CONFIG" << EOF
apiVersion: v1
clusters:
- name: $CLUSTER_NAME
  cluster:
    certificate-authority-data: "$CA"
    server: "$SERVER"
users:
- name: $USER_NAME
  user:
    password: "$PASS"
    username: "$USER"
contexts:
- name: $CONTEXT_NAME
  context:
    cluster: $CLUSTER_NAME
    user: $USER_NAME
current-context: $CONTEXT_NAME
kind: Config
preferences: {}
EOF

fi