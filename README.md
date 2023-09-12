# VMWare VSphere Autoscaler

## Summary

Rough Proof of Concept for Autoscaling Customer Edge Sites in VMware.  Designed to run in vk8s on CE in VMWare, monitors CE resource Utilization and spools up a new worker when threshold is exceeded.

## Installation

Installation can be done via kubectl to your vk8s deployment, or via the Web UI vK8s CronJob interface.  Ensure that all fields are populated correctly.

The first time the job runs might take a bit longer than following jobs.  If the CE Image has to be downloaded and copied to a datastore that can take a few minutes, but once its copied to the datastore it doesnt have to be downloaded again.

### PreRequisite

Your existing site much consist of 3 Controller nodes in order to support worker node additions.

API Token from XC:  <https://docs.cloud.f5.com/docs/how-to/user-mgmt/credentials>

Local DNS resolution will be critical to resolve the vsphere and vcenter hosts. Ensure that your CE where the cronjob will live is using a DNS server that will resolve the hosts accurately.

### Cronjob Manifest

```yaml
kind: CronJob
apiVersion: batch/v1beta1
metadata:
  name: esx-scaler-job-2
  namespace: m-coleman
  annotations:
    ves.io/sites: system/cluster-100
spec:
  schedule: '*/20 * * * *'
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 0
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        metadata:
          annotations:
            ves.io/workload-flavor: medium
            ves.io/sites: system/cluster-100
        spec:
          containers:
            - name: esx-scaler
              image: mcoleman81/esx-scaler:latest
              env:
                - name: VSPHERE_HOST
                  value: 192.168.0.25
                - name: VSPHERE_USER
                  value: administrator@vsphere.local
                - name: VSPHERE_PASS
                  value: pass@word1
                - name: VSPHERE_XC_CLUSTER_PREFIX
                  value: cluster-100
                - name: VSPHERE_NEW_VM_HOST
                  value: vcenter.domain.com
                - name: VSPHERE_VAPP_PREFIX
                  value: scaled-worker
                - name: VSPHERE_DC
                  value: "DC"
                - name: VSPHERE_RESOURCE_POOL
                  value: "XC Limited-Medium"
                - name: VSPHERE_XC_CLUSTER_PREFIX
                  value: "ce-cluster"
                - name: USAGE_HIGH_MARK
                  value: '75'
                - name: USAGE_LOW_MARK
                  value: '25'
                - name: XC_API_TOKEN
                  value: abcdefghijklmnop123456789
                - name: XC_TENANT_URL
                  value: https://acmecorp.console.ves.volterra.io
                - name: XC_SITE_NAME
                  value: xc-site-name
                - name: XC_SITE_ADMIN_PASSWORD
                  value: pass@word1
                - name: XC_SITE_SCALE_IPS
                  value: "192.168.125.66,192.168.125.67,192.168.12.68"
                - name: XC_SITE_SCALE_CIDR
                  value: "24"
              imagePullPolicy: Always
          restartPolicy: Never

```

## Configuration

* ENV VSPHERE_HOST="VSPHERE-IP"

  * This is the IP address of the vsphere server or appliance.

* ENV VSPHERE_USER="administrator"

  * This is the Administrator account.

* ENV VSPHERE_PASS="Pass@word1"

  * This is the Administrator account password.

* ENV VSPHERE_XC_CLUSTER_PREFIX="controller-"

  * This is the prefix used for the controller nodes, it needs to be the same.  If I hae a cluster called Coleman-Cluster-Site, all controller nodes need to have the same prefix in VMWare; "coleman-cluster"

* ENV VSPHERE_NEW_VM_HOST="esx01.domain.com"

  * This is the VMWare Host to put new worker nodes.

* ENV VSPHERE_DC="DC"

  * This is the value for your VSphere Datacenter, this is required, the provider doesnt like to function without it.

* ENV VSPHERE_RESOURCE_POOL="XC Limited-Medium"

  * This is your vSphere Resource Pool.  Default can exist multiple times so can be problematic, so its helpful to create a unique pool to use.

* ENV USAGE_HIGH_MARK=75

  * This is the level of utilization that will cause a new worker node to be added to the cluster.

* ENV USAGE_LOW_MARK=20

  * this is the level of utilization that will cause a worker to be removed from the cluster.

* ENV XC_API_TOKEN="abcdefghijklmnop"
  
  * This is created following the instructions linked above for API Tokens.

* ENV XC_TENANT_URL="<https://acmecorp.console.ves.volterra.io>"

  * This will be the base URL to your XC Tenant.

* ENV XC_SITE_NAME="cluster"

  * This is the name of your Site/Cluster that worker nodes will be added to.

* ENV VSPHERE_XC_CLUSTER_PREFIX="ce-cluster"

  * This is used to gather an agregate from all CE nodes with the site cluster name (prefix).

* ENV VSPHERE_VAPP_PREFIX="scaled-worker"

  * This is the name of the scaled worker nodes to be created in vSphere, and the host names of the workers to be created in the cluster.  It will have the date as well as a sequence number appended to the value.

* ENV XC_SITE_ADMIN_PASSWORD="pass@word1"

  * This is your Site admin password that you want set for scaled worker nodes.

* ENV XC_SITE_SCALE_IPS="192.168.125.66,192.168.125.67,192.168.12.68"

  * This is a list of IP addresses to use for scaled worker nodes.

* ENV XC_SITE_SCALE_CIDR="24"

  * This is the CIDR to use for the IP addresses.

## To Do

* Network Usage has been implemeneted but not as a scaling key.

* Testing and cleanup.
