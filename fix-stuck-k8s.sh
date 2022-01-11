#!/bin/bash

#--------------------------------------------------------------------------------
# How to Fix Deleted Resources Stuck in "Terminating" (like a NS resource)
#
# See:
#  - https://stackoverflow.com/a/52377328 (xargs part)
#  - https://github.com/kubedb/project/issues/684 (finalizers part)
#--------------------------------------------------------------------------------

set -e
set -o pipefail


#--------------------------------------------------
# Find stuck resources
#--------------------------------------------------
NS="<NAMESPACE>"
kubectl api-resources --verbs=list --namespaced -o name \
  | xargs -n 1 kubectl get --show-kind --ignore-not-found -n $NS


#--------------------------------------------------
# From resource types you find above, run:
#--------------------------------------------------

# Example of a found resource:
RESOURCE=postgresclusters.postgres-operator.crunchydata.com

kubectl patch -n $NS $(kubectl get $RESOURCE -o name -n $NS) --type='merge' -p='{"metadata":{"finalizers":null}}'


