# frozen_string_literal: true

RSpec.describe App::Application, async: true do
  describe "#new" do
    subject { described_class.new }

    let(:notifier) { instance_double(App::Notifier, run: true) }
    let(:poller) { instance_double(App::Kubernetes::DeploymentPoller, run: true) }

    before do
      allow(App::Notifier).to receive(:new).and_return(notifier)
      allow(App::Kubernetes::DeploymentPoller).to receive(:new).and_return(poller)
    end

    it "runs" do
      subject
      expect(notifier).to have_received(:run)
      expect(poller).to have_received(:run)
    end
  end
end
