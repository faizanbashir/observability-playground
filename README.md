# Observability Playground

### Directory Structure
I have kept folder structure intact only adding one folder within `./src` folder called `monitoring` which holds all the required code for observability setup. The `monitoring` folder has the following directories:
1. `setup`: This folder contains the files for installing the CRD's.
2. `prometheus`: This folder contains the files for installing the prometheus operator.
3. `alertmanager`: This folder contains the files for installing the alertmanager.
4. `kubestatemetrics`: This folder contains the files for installing Kubestate metrics exporter for exposing kubernetes related metrics.
5. `nodeexporter`: This folder contains the files for installing the Node Exporter for exposing kubernetes node related metrics.
6. `blackboxexporter`: This folder contains the files for installing the BlackBox Exporter for exposing metrics related to http endpoints, this has been used to scrape metrics from the frontend service.
7. `snmpexporter`: This folder contains the files for installing the SNMP Exporter.
8. `mongodb`: This folder contains the files for installing the mongodb exporter to expose metrics related to mongodb.
9. `servicemonitor`: This folder contains the files for installing servicemonitors for monitoring the state of some services in the kubernetes control plane, alertmanager, prometheus, etc. 
10. `app`: This folder contains the files for installing podmonitor, probe and alertmanager rules for our frontend and backend applications.
11. `grafana`: This folder contains the files for installing Grafana, dashboards and configurations.

### Setup scripts
The `init.sh` script invokes the `start-local.sh` script which installs the Kind cluster. Furthermore it goes on to installs kubectl binary, builds, pushes containers images to the local Docker registry and finally installs the frontend and backend applications and services. The `deploy-monitoring.sh` script orchestrates the services for observability including the tools mentioned under the previous heading. The `init.sh` contains the reference to the `start-local.sh` and  `deploy-monitoring.sh` towards the end of the script.

### Integration of the monitoring stack with PagerDuty

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
  name: pagerduty-integration
  labels:
    alertmanagerConfig: pagerduty
spec:
  global:
    resolve_timeout: 1m
    pagerduty_url: 'https://events.pagerduty.com/v2/enqueue'
  route:
    groupBy: ['job']
    groupWait: 30s
    groupInterval: 5m
    repeatInterval: 12h
    receiver: 'pagerduty'
  receivers:
  - name: 'pagerduty'
    pagerduty_configs:
    - service_key: <USER_KEY>
      token: <TOKEN>
      send_resolved: true
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: pagerduty-config
data:
  apiSecret: V2hhdFRoZVBhZ2VyRHV0eQ==
```

### Pre-requisites
1. These scripts have been developed and tested in a MacBook Pro OS Monterey (v12.1). I have not tested these scripts on Windows on Linux machines. Although the scripts should run on Linux machines with the exception of the installation of the `kubectl` utility which might have to be installed in a different bin path.
2. `Docker` and `Kind` should be installed.
3. The init script require `sudo` access to install the proper version of `kubectl` command-line utility in the `/usr/local/bin/kubectl` directory.