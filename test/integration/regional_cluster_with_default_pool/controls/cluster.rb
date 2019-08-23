# frozen_string_literal: true
project_id = attribute('project_id')
cluster = attribute('source_cluster')

include_controls 'cluster-baseline'
include_controls 'outputs' do
  skip_control 'node-pools-output'
end

control 'gcloud-regional-cluster' do
  title 'Google Kubernetes Engine Regional Configuration control'
  describe "Cluster #{cluster['name']}" do
    subject do
      command("gcloud beta container clusters describe #{cluster['name']} " \
              "--format=json --region=#{cluster['location']} --project=#{project_id}")
    end

    let(:zones) do
      cmd = "gcloud compute zones list --filter=\"region:(#{cluster['location']})\" " \
            "--format=json --project=#{project_id}"
      zones_output = command(cmd).stdout
      JSON.parse(zones_output).map { |zone| zone['name'] }
    end

    let(:data) do
      if subject.exit_status == 0
        JSON.parse(subject.stdout)
      else
        {}
      end
    end

    it "uses all adjacent zones to #{cluster['location']} as locations" do
      expect(data['locations']).to match_array(zones)
    end
  end
end
