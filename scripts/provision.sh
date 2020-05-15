#!/usr/bin/env bash

ansible-playbook -i inventory.ini playbooks/provision.yml --ask-pass