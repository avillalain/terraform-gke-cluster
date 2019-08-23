# frozen_string_literal: true
cluster = attribute('source_cluster')
node_pools = attribute('source_node_pools')
service_account = attribute('source_service_account')
project_id = attribute('project_id')

control 'gcloud-node-pool-baseline' do
  title 'Google Kubernetes Engine Default Node Pool Configuration control'
  node_pools.each do |node_pool|
    describe "Node pool: #{node_pool['name']}, " do
      before(:all) do
        node_pool_cmd = "gcloud beta container node-pools describe #{node_pool['name']} " \
                        "--project=#{project_id} --cluster=#{cluster['name']} "\
                        "--zone=#{cluster['location']} --format=json"
        @node_pool_response = command(node_pool_cmd)
        region_cmd = "gcloud compute regions list --project=#{project_id} "\
                     "--filter=\"zones:(#{cluster['location']})\" " \
                     "--format=json"
        location = JSON.parse(command(region_cmd).stdout).map { |region| region['name'] }[0]
        zones_command = "gcloud compute zones list --filter=\"region:(#{location})\" " \
                        "--format=json --project=#{project_id}"
        @zones = JSON.parse(command(zones_command).stdout).map { |zone| zone['name'] }
      end

      let(:data) do
        JSON.parse(@node_pool_response.stdout)
      end

      it "is located in #{@zones}" do
        expect(data['locations']).to match_array(@zones)
      end

      it "has autoscaling enabled" do
        expect(data['autoscaling']['enabled']).to be true
      end

      it "has a min count of #{node_pool['min_nodes']} nodes" do
        expect(data['autoscaling']['minNodeCount']).to eq node_pool['min_nodes']
      end

      it "has a max count of #{node_pool['max_nodes']} nodes" do
        expect(data['autoscaling']['maxNodeCount']).to eq node_pool['max_nodes']
      end

      it "has auto_repair turned on" do
        expect(data['management']['autoRepair']).to be true
      end

      it "has auto_update turned on" do
        expect(data['management']['autoUpgrade']).to be true
      end

      it "has a maximum number of #{node_pool['max_pods_per_node']} pods per node" do
        expect(data['maxPodsConstraint']['maxPodsPerNode']).to eq node_pool['max_pods_per_node'].to_s
      end

      it "has a #{node_pool['name']} as its name" do
        expect(data['name']).to eq node_pool['name']
      end

      it "has a disk of #{node_pool['disk_size_gb']} GB" do
        expect(data['config']['diskSizeGb']).to eq node_pool['disk_size_gb']
      end

      it "is a #{node_pool['disk_type']} disk type" do
        expect(data['config']['diskType']).to eq node_pool['disk_type']
      end

      it "has some labels" do
        labels = { 'cluster_name' => cluster['name'], 'node_pool' => node_pool['name'] }
          .deep_merge(node_pool['labels'])
        expect(data['config']['labels']).to eq labels
      end

      it "has some a ssd count of #{node_pool['ssd_count']}" do
        expect(data['config']['localSsdCount']).to eq node_pool['ssd_count']
      end

      it "is a #{node_pool['machine_type']} machine type" do
        expect(data['config']['machineType']).to eq node_pool['machine_type']
      end

      it "has the following metadata" do
        metadata = {
          'cluster_name' => cluster['name'],
          'node_pool' => node_pool['name'],
          'disable-legacy-endpoints' => "true",
        }.deep_merge(node_pool['metadata'])
        expect(data['config']['metadata']).to eq metadata
      end

      it "has a minimum cpu platform of #{node_pool['min_cpu_platform']}" do
        expect(data['config']['minCpuPlatform']).to eq node_pool['min_cpu_platform']
      end

      it "has some tags" do
        tags = ["gke-#{cluster['name']}", "gke-#{cluster['name']}-#{node_pool['name']}"] + node_pool['tags']
        expect(data['config']['tags']).to eq tags
      end

      it "has some taints" do
        expect(data['config']['taints']).to eq node_pool['taints']
      end

      it "has a new service account created" do
        expect(data['config']['serviceAccount']).to start_with service_account['name']
      end
    end
  end
end
