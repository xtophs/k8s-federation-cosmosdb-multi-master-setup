#!/bin/bash

kubectl delete -f rs/items-rs.yaml --context=myfederation
kubectl delete -f svc/items-svc.yaml --context=myfederation

kubectl delete -f configmaps/cosmos-env-configmap-west.yaml --context=fed-west
kubectl delete -f configmaps/cosmos-env-configmap-east.yaml --context=fed-east
