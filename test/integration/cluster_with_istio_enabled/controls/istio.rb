# frozen_string_literal: true
project_id = attribute('project_id')
cluster = attribute('source_cluster')

include_controls 'cluster-baseline'
include_controls 'outputs' do
  skip_control 'node-pools-output'
end

control 'gcloud-istio-cluster' do
  title 'Google Kubernetes Engine Istio Configuration control'
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

    it "has istio enabled and with authentication type #{cluster['addons']['istio']['authentication']}" do
      expect(data['addonsConfig']['istioConfig']['auth']).to eq cluster['addons']['istio']['authentication']
    end
  end
end
