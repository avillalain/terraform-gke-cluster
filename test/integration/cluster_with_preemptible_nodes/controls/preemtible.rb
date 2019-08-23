# frozen_string_literal: true
cluster = attribute('source_cluster')
node_pools = attribute('source_node_pools')
project_id = attribute('project_id')

include_controls 'cluster-baseline'
include_controls 'node-pool-baseline'
include_controls 'outputs'

control 'gcloud-preemptible-node-pool' do
  title 'Google Kubernetes Engine with Preemptible Node Pool Configuration control'
  node_pools.each do |node_pool|
    describe "Node pool: #{node_pool['name']}," do
      before(:all) do
        node_pool_cmd = "gcloud beta container node-pools describe #{node_pool['name']} " \
                        "--project=#{project_id} --cluster=#{cluster['name']} "\
                        "--zone=#{cluster['location']} --format=json"
        @node_pool_response = command(node_pool_cmd)
      end

      let(:data) do
        JSON.parse(@node_pool_response.stdout)
      end

      it "has preemptible vms" do
        expect(data['config']['preemptible']).to eq true
      end
    end
  end
end
