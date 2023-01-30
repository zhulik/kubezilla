# frozen_string_literal: true

require "zilla"
require "memery"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem

module Kubezilla
  class Error < StandardError; end

  def self.for(host:, scheme:, &)
    Kubezilla::Client.new(host:, scheme:, &)
  end
  # Your code goes here...
end

loader.setup
loader.eager_load
