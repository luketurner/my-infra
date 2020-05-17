#!/usr/bin/env bash
set -e

if [[ "$1" == "--user" ]]; then
  scripts/initial_login
elif [[ "$1" == "--static-ip" ]]; then
  ansible-playbook -i inventory.ini playbooks/pinode/static_ip.yml
else
  ansible-playbook -i inventory.ini playbooks/pinode/main.yml
  ansible-playbook -i inventory.ini playbooks/pinode/k3s.yml
fi