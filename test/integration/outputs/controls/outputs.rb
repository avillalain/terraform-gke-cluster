# frozen_string_literal: true
service_account = attribute('service_account')
cluster = attribute('cluster')
node_pools = attribute('node_pools')

RSpec::Matchers.define :be_boolean do
  match do |actual|
    expect(actual).to be_in([true, false])
  end
end

control 'service-account-output' do
  describe 'service-account' do
    it 'should return a service account object with additional email' do
      expect(service_account).to match(
        "email" => an_instance_of(String),
        "name" => an_instance_of(String),
        "description" => an_instance_of(String),
        "additional_roles" => all(an_instance_of(String))
      )
    end
  end
end

control 'cluster-output' do
  describe 'cluster' do
    it 'should return a cluster object with the node locations' do
      expect(cluster).to match(
        "name" => an_instance_of(String),
        "location" => an_instance_of(String),
        "network" => an_instance_of(String),
        "subnetwork" => an_instance_of(String),
        "addons" => {
          "istio" => {
            "enabled" => be_boolean,
            "authentication" => an_instance_of(String),
          },
          "cloud_run" => {
            "enabled" => be_boolean,
          },
        },
        "description" => an_instance_of(String),
        "binary_auth_enabled" => be_boolean,
        "initial_node_count" => an_instance_of(Integer),
        "ip_alias" => {
          "pod_address_range_name" => an_instance_of(String),
          "service_address_range_name" => an_instance_of(String),
        },
        "services" => {
          "stackdriver_monitoring_enabled" => be_boolean,
        },
        "maintenance_window" => an_instance_of(String),
        "master_cidr_block" => an_instance_of(String),
        "authorized_networks" => all(a_hash_including(
          "cidr_block" => an_instance_of(String),
          "name" => an_instance_of(String),
        )),
        "cluster_version" => an_instance_of(String),
        "labels" => an_instance_of(Hash),
        "node_locations" => all(an_instance_of(String)),
      )
    end
  end
end

control 'node-pools-output' do
  describe 'node pools' do
    it 'should return a list of node pool object' do
      node_pools.each do |node_pool|
        expect(node_pool).to match(
          "min_nodes" => an_instance_of(Integer),
          "max_nodes" => an_instance_of(Integer),
          "max_pods_per_node" => an_instance_of(Integer),
          "name" => an_instance_of(String),
          "disk_size_gb" => an_instance_of(Integer),
          "disk_type" => an_instance_of(String),
          "labels" => an_instance_of(Hash),
          "ssd_count" => an_instance_of(Integer),
          "machine_type" => an_instance_of(String),
          "metadata" => an_instance_of(Hash),
          "min_cpu_platform" => an_instance_of(String),
          "preemptible" => be_boolean,
          "tags" => all(an_instance_of(String)),
          "taints" => all(a_hash_including(
            "effect" => an_instance_of(String),
            "key" => an_instance_of(String),
            "value" => an_instance_of(String),
          )),
        )
      end
    end
  end
end
