# frozen_string_literal: true
project_id = attribute('project_id')
cluster = attribute('source_cluster')
service_account = attribute('source_service_account')
network_name = attribute('network_name')
subnetwork_name = attribute('subnetwork_name')

control 'gcloud-cluster-baseline' do
  title 'Google Kubernetes Engine Default Configuration control'

  describe "Cluster #{cluster['name']}" do
    before(:all) do
      regions = JSON.parse(command("gcloud compute regions list --project=#{project_id} --format=json")
                          .stdout).map { |region| region['name'] }
      filter_by = regions.include?(cluster['location']) ? "region" : "zone"
      master_version_cmd = "gcloud container get-server-config --format=json --#{filter_by}=#{cluster['location']}"
      cluster_cmd = "gcloud beta container clusters describe #{cluster['name']} " \
                    "--format json --#{filter_by}=#{cluster['location']}"
      @cluster_response = command(cluster_cmd)
      @master_version_response = command(master_version_cmd)
    end

    let(:data) do
      if @cluster_response.exit_status == 0
        JSON.parse(@cluster_response.stdout)
      else
        {}
      end
    end

    let(:latest_master_version) do
      if @master_version_response.exit_status == 0
        JSON.parse(@master_version_response.stdout)['validMasterVersions'][0]
      else
        {}
      end
    end

    let(:master_authorized_networks) do
      cluster['authorized_networks'].map do |network|
        { "cidrBlock" => network['cidr_block'], "displayName" => network['name'] }
      end
    end

    let(:version) do
      cluster['cluster_version'] == "latest" ? latest_master_version : cluster['cluster_version']
    end

    it "has a name of #{cluster['name']}" do
      expect(data['name']).to eq cluster['name']
    end

    it "is located at #{cluster['location']}" do
      expect(data['location']).to eq cluster['location']
    end

    it "has hpa enabled" do
      expect(data['addonsConfig']['horizontalPodAutoscaling']).to eq({})
    end

    it "has http load balancing enabled" do
      expect(data['addonsConfig']['httpLoadBalancing']).to eq({})
    end

    it "has the dashboard disabled" do
      expect(data['addonsConfig']['kubernetesDashboard']['disabled']).to be true
    end

    it "has the network policy config enabled" do
      expect(data['addonsConfig']['networkPolicyConfig']).to eq({})
      expect(data['networkPolicy']['enabled']).to be true
      expect(data['networkPolicy']['provider']).to eq "CALICO"
    end

    it "has not enabled cluster autoscaling" do
      expect(data['autoscaling']).to eq({})
    end

    it "is described as #{cluster['description']}" do
      expect(data['description']).to eq cluster['description']
    end

    it "has an initial node count of #{cluster['initial_node_count']}" do
      expect(data['initialNodeCount']).to eq(cluster['initial_node_count'])
    end

    it "uses IP Aliases" do
      expect(data['ipAllocationPolicy']['useIpAliases']).to be true
      expect(data['ipAllocationPolicy']['clusterSecondaryRangeName'])
        .to eq cluster['ip_alias']['pod_address_range_name']
      expect(data['ipAllocationPolicy']['servicesSecondaryRangeName'])
        .to eq cluster['ip_alias']['service_address_range_name']
    end

    it "has a maintenance window at #{cluster['maintenance_window']}" do
      expect(data['maintenancePolicy']['window']['dailyMaintenanceWindow']['startTime'])
        .to eq(cluster['maintenance_window'])
    end

    it "does not allowed user/password authentication" do
      expect(data['masterAuth']).to_not have_key('username')
      expect(data['masterAuth']).to_not have_key('password')
    end

    it "does not issue a client certificate" do
      expect(data['masterAuth']).to_not have_key('clientCertificateConfig')
    end

    it "is part of network #{network_name}" do
      expect(data['network']).to eq network_name
    end

    it "is part of subnetwork #{subnetwork_name}" do
      expect(data['subnetwork']).to eq subnetwork_name
    end

    it "does not enable legacy abac" do
      expect(data['legacyAbac']).to eq({})
    end

    it "has resource labels" do
      expect(data['resourceLabels']).to eq cluster['labels']
    end

    it "has disabled vertical pod autoscaling" do
      expect(data['legacyAbac']).to eq({})
    end

    it "has pod security policy config enabled" do
      expect(data['podSecurityPolicyConfig']['enabled']).to be true
    end

    it "has intranode visibility enabled" do
      expect(data['networkConfig']['enableIntraNodeVisibility']).to be true
    end

    it "allows access to the specified authorized networks" do
      expect(data['masterAuthorizedNetworksConfig']['cidrBlocks']).to match_array(master_authorized_networks)
    end

    it "is running the #{cluster['cluster_version']}" do
      expect(data['initialClusterVersion']).to eq version
    end

    it "disables nodes public access" do
      expect(data['privateClusterConfig']['enablePrivateNodes']).to be true
    end

    it "has a #{cluster['master_cidr_block']} cidr range for the master nodes" do
      expect(data['privateClusterConfig']['masterIpv4CidrBlock']).to eq cluster['master_cidr_block']
    end

    it "has a new service account created" do
      expect(data['nodeConfig']['serviceAccount']).to start_with service_account['name']
    end
  end
end
