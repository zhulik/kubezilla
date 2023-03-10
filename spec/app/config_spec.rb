# frozen_string_literal: true

RSpec.describe App::Config do
  describe ".build" do
    subject { described_class.build }

    it "returns an instance of Config" do
      expect(subject).to be_an_instance_of(described_class)
      expect(subject).to have_attributes({
                                           kubernetes_url: "127.0.0.1:8001",
                                           kubernetes_scheme: "http",
                                           notification_webhook_url: "https://example.com"
                                         })
    end
  end
end
