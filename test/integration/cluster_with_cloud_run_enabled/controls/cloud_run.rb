# frozen_string_literal: true
project_id = attribute('project_id')
cluster = attribute('source_cluster')

include_controls 'cluster-baseline'
include_controls 'outputs' do
  skip_control 'node-pools-output'
end

control 'gcloud-cloud-run-cluster' do
  title 'Google Kubernetes Engine Cloud Run Configuration control'
  describe "Cluster #{cluster['name']}" do
    subject do
      command("gcloud beta container clusters describe #{cluster['name']} " \
              "--format=json --zone=#{cluster['location']} --project=#{project_id}")
    end
    let(:data) do
      if subject.exit_status == 0
        JSON.parse(subject.stdout)
      else
        {}
      end
    end

    it "has cloud run enabled" do
      # google beta provider returns an empty cloudRunConfig object when enabled
      expect(data['addonsConfig']['cloudRunConfig']).to eq({})
    end
  end
end
