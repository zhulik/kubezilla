# frozen_string_literal: true

RSpec.describe App::Counter do
  let(:counter) { described_class.new }

  describe "#add" do
    subject { counter.add("key", "payload") }

    context "when there is no item with given key" do
      it("adds a record") { expect { subject }.to change { counter.include?("key") }.from(false).to(true) }

      it("change sets counter for item to 1") do
        subject
        expect(counter.counter("key")).to eq(1)
      end

      it("assigns payload") do
        subject
        expect(counter.get("key")).to eq("payload")
      end
    end

    context "when there is an item with given key" do
      before { counter.add("key", "first_payload") }

      it("increases a counter for") { expect { subject }.to change { counter.counter("key") }.by(1) }

      it("does not change already stored payload") { expect { subject }.not_to(change { counter.get("key") }) }
    end
  end

  describe "#get" do
    subject { counter.get("key") }

    context "when there is an item with given key" do
      context "when payload was not provided" do
        before { counter.add("key") }

        it("returns nil") { expect(subject).to be_nil }
      end

      context "when payload was provided" do
        before { counter.add("key", "payload") }

        it("returns nil") { expect(subject).to eq("payload") }
      end
    end

    context "when there is no item with given key" do
      it("raises KeyError") { expect { subject }.to raise_error(KeyError, 'key not found: "key"') }
    end
  end

  describe "#remove" do
    subject { counter.remove("key") }

    context "when there is no item with given key" do
      it("raises KeyError") { expect { subject }.to raise_error(KeyError, 'key not found: "key"') }
    end

    context "when there is an item with given key" do
      before { counter.add("key", "payload") }

      context "when it's counter is 1" do
        it("removes the record") { expect { subject }.to change { counter.include?("key") }.from(true).to(false) }
        it("returns payload") { expect(subject).to eq("payload") }
      end

      context "when it's counter is > 1" do
        before { counter.add("key") }

        it("decreases the counter") { expect { subject }.to change { counter.counter("key") }.by(-1) }
        it("returns nil") { expect(subject).to be_nil }
      end
    end
  end
end
