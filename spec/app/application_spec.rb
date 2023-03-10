# frozen_string_literal: true

RSpec.describe App::Application, async: true do
  let(:app) { described_class.new }

  describe "#start!" do
    subject { app.start! }

    after { app.stop! }

    before do
      allow(Zilla::Kubernetes).to receive(:new)
    end

    it "initializes Zilla::Kubernetes" do
      subject
      expect(Zilla::Kubernetes).to have_received(:new)
    end
  end
end
