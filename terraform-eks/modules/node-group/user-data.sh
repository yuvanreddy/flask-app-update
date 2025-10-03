#!/bin/bash
set -o xtrace

# Bootstrap the node to join the EKS cluster
/etc/eks/bootstrap.sh ${cluster_name}

# Additional custom configurations can be added here
# For example: installing monitoring agents, setting up logging, etc.