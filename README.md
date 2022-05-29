# SRE Challenge

Hi, 

This assignment was pretty interesting and I found it worth spending my time working on it. The assigment was delayed on my part due increased workload, I finally got the time to work on it this Sunday (29th May, 2022).

I have made a few changes to the original code as follows:
1. Updated the backend python code to emit Prometheus metics on the path `/metrics` and added the required library to the `requirements.txt` file.
2. Updated the deployment files for backend and frontend to use the local Docker registry hosted at `localhost:5000`.
3. Updated the Kind cluster installation command to use a specific version of kubernetes (`v1.23.6`), same goes for the kubectl binary.
4. Added commands to build and push the frontend and backend images to local Docker registry.
5. Updated the README.md file ;)

### Directory Structure
I have kept folder structure intact only adding one folder within `./src` folder called `monitoring` which holds all the required code for observability setup. The `monitoring` folder has the following directories:
1. `setup`: This folder contains the files for installing the CRD's.
2. `prometheus`: This folder contains the files for installing the prometheus operator.
3. `alertmanager`: This folder contains the files for installing the alertmanager.
4. `kubestatemetrics`: This folder contains the files for installing Kubestate metrics exporter for exposing kubernetes related metrics.
5. `nodeexporter`: This folder contains the files for installing the Node Exporter for exposing kubernetes node related metrics.
6. `blackboxexporter`: This folder contains the files for installing the BlackBox Exporter for exposing metrics related to http endpoints, this has been used to scrape metrics from the frontend service.
7. `mongodb`: This folder contains the files for installing the mongodb exporter to expose metrics related to mongodb.
8. `servicemonitor`: This folder contains the files for installing servicemonitors for monitoring the state of some services in the kubernetes control plane, alertmanager, prometheus, etc. 
9. `app`: This folder contains the files for installing podmonitor, probe and alertmanager rules for our frontend and backend applications.
10. `grafana`: This folder contains the files for installing Grafana, dashboards and configurations.

### Setup scripts
The `start-local.sh` apart from installing the Kind cluster, installs kubectl binary, builds, pushes containers images to the local Docker registry and finally installs the frontend and backend applications and services. The `deploy-monitoring.sh` script orchestrates the services for observability including the tools mentioned under the previous heading. The `start-local.sh` contains the reference to the `deploy-monitoring.sh` towards the end of the script.

### Integration of the monitoring stack with PagerDuty
Although I have not added the code for integration with PagerDuty in the monitoring scripts. I have provided a snippet here to show how we can integrate with PagerDuty. 

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

I have not used PagerDuty with Alertmanager before. But I have done integrations for OpsGenie and ServiceNow.