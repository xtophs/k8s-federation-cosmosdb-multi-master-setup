#!/bin/bash

kubectl create -f configmaps/cosmos-west-configmap.yaml --context=fed-west
kubectl create -f configmaps/cosmos-east-configmap.yaml --context=fed-east

kubectl create -f rs/items-rs.yaml --context=myfederation
kubectl create -f svc/items-svc.yaml --context=myfederation




