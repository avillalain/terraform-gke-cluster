# frozen_string_literal: true
project_id = attribute('project_id')
cluster = attribute('source_cluster')

include_controls 'cluster-baseline'
include_controls 'outputs' do
  skip_control 'node-pools-output'
end

control 'gcloud-stackdriver-engine-cluster' do
  title 'Google Kubernetes Engine Stackdriver Kubernetes Engine Control'
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

    it "has the stackdriver kubernetes engine enabled" do
      expect(data['loggingService']).to eq "logging.googleapis.com/kubernetes"
      expect(data['monitoringService']).to eq "monitoring.googleapis.com/kubernetes"
    end
  end
end
