## Installations Script
* docker-compose.yaml
* install.sh
  * ./install_docker_centos8.sh
  * ./install_docker_compose.sh
  * ./install_docker_compose_rancher.sh
## Rancher 2.5.0 Changes
What's New in 2.5
Cluster Explorer: New dashboard to provide a deeper look into clusters under management.
Manage all Kubernetes cluster resources including custom resources from the Kubernetes operator ecosystem
Deploy and manage Helm charts from our new Apps & Marketplace
View logs and interact with kubectl shell in a new IDE-like viewer
Monitoring and Alerting powered by Prometheus: Allows management of custom Grafana dashboards and provide customization to AlertManager
Logging powered by Banzai Cloud: Customize FluentBit and Fluentd configurations and ship logs to a remote data store
CIS Scans powered by kube-bench: Extended support to perform CIS scans tailored for EKS and GKE platforms and perform a generic scan on any Kubernetes distribution
Istio 1.7+: Allows users to deploy multiple ingress and egress gateways
Rancher Continuous Delivery powered by Fleet: Fleet is a built-in deployment tool for delivering applications and configurations from a Git source repository across multiple clusters.
Deploy any Kubernetes resource defined by manifests, kustomize, or Helm
Scale deployments to any number of clusters using a staged checkout and pull-based update model
Organize clusters into groups for easier management
Map Git source repositories to cluster group targets
Enhanced EKS Lifecycle Management:
Provisioning has been enhanced to support managed node groups, private access, and control plane logging
Registering existing EKS clusters allow management of upgrades and configuration
Rancher Server Backups:
Back up Rancher server without access to the etcd database
Restore data into any Kubernetes cluster