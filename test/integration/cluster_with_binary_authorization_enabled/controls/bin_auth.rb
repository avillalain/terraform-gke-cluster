# frozen_string_literal: true
project_id = attribute('project_id')
cluster = attribute('source_cluster')

include_controls 'cluster-baseline'
include_controls 'outputs' do
  skip_control 'node-pools-output'
end

control 'gcloud-bin-auth-cluster' do
  title 'Google Kubernetes Engine Binary Authorization Configuration control'
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

    it "has binary authorization enabled" do
      expect(data['binaryAuthorization']['enabled']).to be true
    end
  end
end
