# Terraform GCP Base Kubernetes Engine Module

A Terraform module for provisioning a base kubernetes cluster in GCP.

It supports the creation of:

- Regional and Zonal Clusters with the following characteristics:
  - Horizontal Pod Autoscaling enabled by default
  - HTTP Load balancing enabled by default
  - Kubernetes Dashboard disabled by default
  - Network Policy enabled by default
  - Istio and Cloud Run features can be enabled
  - Cluster autoscaling is disabled by default
  - Binary Authorization can be enabled
  - IP Aliases is enabled by default
  - Monitoring and Logging services with Stackdriver can be enabled
  - It disabled username/password and client certificate generation by default
  - Private Cluster with masters accessible for configured networks
  - PodSecurityPolicy is enabled by default
  - It enables intranode visibility by default
- If node pools are not specified it creates a default node pool based on the container default node pool.
- If node poools are specified, automatic upgrades and automatic repair are enabled by default. The rest of parameters are configurable too, except for GPU support.
- Node locations are not configurable.
  - If the location specified is a region, it selects all zones within the region for additional node locations.
  - If the location is a zone, it uses all zones in the same region for additional node locations.
- It creates a service account to be used by node VMs. It allows you to specify additional roles for such account.

## Compatibility

This module is meant for use with Terraform 0.12. Please refer to the [upgrade guide](https://www.terraform.io/upgrade-guides/0-12.html) for more information. This module make use of some GCP beta features.

## Usage

Have a look at the examples inside the test fixture folder. However, you can include something like the following in your terraform configuration:

```hcl
module "cluster" {
    source  = "github.com/avillalain/terraform-gke-cluster
    project = "your-project-id"
    cluster = {
      name = "cluster-name"
      location = "us-east-1"
      network = "network-name"
      subnetwork = "subnetwork-name"
      addons = {
        istio = {
          enabled = true
          authentication = "AUTH_NONE"
        }
      }
      cloud_run = {
        enabled = true
      }
      description = "a description"
      binary_auth_enabled = true
      initial_node_coount = 3
      ip_alias = {
        pod_address_range_name = "name-of-secondary-ip-range"
        service_address_range_name = "name-of-secondary-ip-range"
      }
      services = {
        stackdriver_monitoring_enabled = true
      }
      maintenance_window = "3:00"
      master_cidr_block = "10.193.24.0/28"
      authorized_networks = [
        {
          cidr_block = "0.0.0.0/0"
          name = "all-for-testing"
          labels = {
            "some" = "labels"
          }
        }
      ]
    }
    node_pools = {
      min_nodes = 1
      max_nodes = 3
      max_pods_per_node = 50
      name = "node-pool-name"
      disk_size_gb = 10
      disk_type = "pd-standard"
      labels = {
        "some" = "labels"
      }
      ssd_count = 1
      machine_type = "n1-standard-1"
      metadata = {
        "some" = "metadata"
      }
      min_cpu_platform = "Intel Skylake"
      preemptible = false
      tags = ["some", "tags"]
      taints = [
        {
          effect = "PREFER_NO_SCHEDULE"
          key = "dedicated"
          value = "experimental"
        }
      ]
    }
    service_account = {
      name = "service-account-name"
      description = "a descirption"
      additional_roles = ["some", "roles"]
    }
}
```

## Inputs

As you can see from the above snippet there are four main inputs

| Field | Description | Type | Required |
|-------|-------------|------|----------|
| project | The project id | string | optional |
| cluster | An object that provides all configuration parameters associated with the cluster. | object | true |
| node_pools | A list of node pool configuration objects that holds all configuration parameters associated to a node pool | list(object) | false (default empty list) |
| service_account | An object that provides all configuration parameters for the service account used by node VMs | object | true |

As of Terraform 0.12.6, there is no way of specifying optional parameters for an object. So for that reason all parameters of each object are required. Only way to avoid specifying something is by simply declared them empty or null.

### Cluster Inputs

| Field | Description | Type |
|-------|-------------|------|
| name | the name of the cluster to be created. | string |
| location | the name of the region or zone for the cluster. If a region is chosen, then gcp will create a master node in each zone for that region. If zone is chose, the cluster will have only a single master | string |
| network | the name of the vpc network or the self\_link where the cluster will be created. | string |
| subnetwork |the name of the vpc subnetwork or the self\_link where the cluster will be created. | string |
| addons | The addons object for this cluster. See the addons input for more info. | object |
| description | a description for this cluster. | string |
| binary\_auth\_enabled | If enabled all container images will be validated by Google Binary Authorization. | bool |
| initial\_node\_count | the number of nodes to create in this cluster's default node pool. Must be set to at least 1, since a cluster cannot be created without a node pool. | number |
| ip\_alias | the ip alias object for this cluster. See the IP Alias section for more info. | object |
| services |  the services object configuration for this cluster. See the services section for more info. | object |
| maintenance\_window | the time window specified for daily maintenance operations. It must be in "HH:MM" format. | string |
| master\_cidr\_block | the ip range for the hosted master network. Must not overlap other ranges and must be a /28 subnet .| string |
| authorized\_networks | the authorized network configuration object. See its section for more information | object |
| cluster\_version | the version of the kubernetes cluster. Use latest if you want to use the latest version available in either the region or the zone location. | string |
| labels | a map of labels | map(string) |

#### Addons Object

The addons input contain two main configuration objects, mainly `istio` and `cloud_run`.

##### Istio Object

| Field | Description | Type |
|-------|-------------|------|
| enabled | set this to `true` if you want to enable istio | boolean |
| authentication | set this to `AUTH_MUTUAL_TLS` for strict mTLS or `AUTH_NONE` for permissive | string |

##### Cloud Run Object

| Field | Description | Type |
|-------|-------------|------|
| enabled | set this to `true` if you want to enable cloud run | boolean |

#### IP Alias Object

| Field | Description | Type |
|-------|-------------|------|
| pod\_address\_range\_name | the name of the subnetwork secondary ip range that's going to be used for pod addresses  | string |
| service\_address\_range\_name | the name of the subnetwork secondary ip range that's going to be used for service addresses  | string |

#### Services Object

| Field | Description | Type |
|-------|-------------|------|
| stackdriver\_monitoring\_enabled | if set to true, this will enable kubernetes engine stack driver integration for logging and monitoring | boolean |

#### Authorized Networks Object

The list of external networks that can access the Kubernetes cluster master. Each object in the list must specify the following parameters.

| Field | Description | Type |
|-------|-------------|------|
| cidr\_block | the cidr range of the network | string |
| name | a name to identify this range | string |

### Node Pools Inputs

| Field | Description | Type |
|-------|-------------|------|
| min\_nodes | Minimum number of nodes in the node pool | number |
| max\_nodes | Maximum number of nodes the node pool can scale to | number |
| max\_pods\_per\_node | the maximum number of pods per node. | number |
| name | the name of this node pool. | string |
| disk\_size\_gb | the size of the disk attached to each node | number |
| disk\_type | the type of disk attached. Either `pd-standard` or `pd-ssd` | string
| labels | the labels applied to each node | map(string) |
| ssd\_count | the amount of ssd disks attached to each node | number |
| machine\_type | the name of the compute engine machine type | string |
| metadata | metadata assigned to instances in the cluster | map(string)
| min\_cpu\_platform | minimum cpu platform used by eacn node instance | string |
| preemptible | a boolean flag that represents whether or not to use preemtible VMs | bool |
| tags | the list of instance tags applied to all nodes | list(string) |
| taints | the list of kubernetes taints object applied to each node | list(object) |

#### Taint Input

| Field | Description | Type |
|-------|-------------|------|
| effect | the effect for taint. Accepted values are `NO\_SCHEDULE`, `PREFER\_NO\_SCHEDULE` and `NO\_EXECUTE`. | string |
| key | key for taint | string |
| value | value for taint | string |

### Service Account Inputs

| Field | Description | Type |
|-------|-------------|------|
| name | the name for this service account | string |
| descirption | a description for this services account | string |
| additional\_roles | a list of additional roles for the service account.  |list(string)

By default, if no additional roles are specified the service account will be created with the following roles:

- `roles/logging.logWriter`
- `roles/monitoring.metricWriter`
- `roles/monitoring.viewer`
- `roles/stackdriver.resourceMetadata.writer`

## Outputs

The output of this module are the same content as the inputs, some extra computed values. See `cluster.tf`, `nodes.tf` and `service_account.tf` for more info.

## File structure

The project has the following folders and files:

- /: root folder
- /test/fixtures: The fixture for our test harness, but it also serves as examples on how to use this module
- /test: Folders with files for testing the module
- /inputs.tf: all the input variables for this module
- /cluster.tf: all the resources and outputs related to the cluster
- /nodes.tf: all the resources and outputs related to the node pools
- /locals.tf: all the local computed values used throughout the module
- /service_account.tf: all the resources related to the service account
- /output.tf the outputs for this module

## Testing and documentation generation

### Requirements

- [kitchen-terraform](https://github.com/newcontext-oss/kitchen-terraform)
- [gcloud](https://cloud.google.com/sdk/gcloud/)
- Ruby 2.6.2
- Bundler

### Testing

First install all requirments:

```bash
bundle install --binstubs
```

Install and configure your [gcloud-sdk](https://cloud.google.com/sdk/gcloud/). Create a google project, and store the `project id` in an environmental variable called `GOOGLE_PROJECT`. You must also have a `Service` account with the following roles:

- `Compute Admin`
- `Kubernetes Engine Admin`
- `Security Admin`
- `Create Service Accounts`
- `Delete Service Accounts`
- `Service Account User`

After that, configure the service account with the roles documented above and export the JSON key. Create an enviromentable variable called `GOOGLE_APPLICATION_CREDENTIALS` and store the path location pointing to the JSON key.

Once that is done, execute the following command to run the test:

```bash
TF_VAR_project_id=$GOOGLE_PROJECT_ID kitchen test
```

Be aware of time and costs. Executing all the tests will take a lot of time! :D

## Collaboration

Everyone is welcome to collaborate and propose ideas. In fact I would love to hear from your input and recommendations. I'm fairly new to ruby and I would love your feedback! Also if you find anything funky with the documentation so far feel free to point it out, English is not my first language.

## TODOS

- Add dns zone stubdomains as an option
- Add ip masq
- Add tiller/helm
- Add support for private master nodes with no public access
- Change `Istio` Authentication paramaters to be more descriptive rather than using the GCP provider strings
- Remove extra objects.
- Be able to delete all resources created. When creating a cluster, and istio is enabled, a number of firewall rules are created and never delete if the cluster is deleted.
