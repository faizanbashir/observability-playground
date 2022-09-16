#!/bin/bash

# create namespace and install CRDs
kubectl create -f ./src/monitoring/setup

# install prometheus operator
kubectl create -f ./src/monitoring/prometheus

# install alertmanager 
kubectl create -f ./src/monitoring/alertmanager

# install kubestatmetrics
kubectl create -f ./src/monitoring/kubestatmetrics

# install nodeexporter
kubectl create -f ./src/monitoring/nodeexporter

# install blackboxexporter
kubectl create -f ./src/monitoring/blackboxexporter

# install snmp exporter
kubectl create -f ./src/monitoring/snmpexporter

# install mongodbexporter
kubectl create -f ./src/monitoring/mongodb

# install servicemonitors
kubectl create -f ./src/monitoring/servicemonitor

# install app related podmonitor, probe and alertmanager rules
kubectl create -f ./src/monitoring/app

# wait for CRD creation to complete
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done

# install Grafana
kubectl create -f ./src/monitoring/grafana