# frozen_string_literal: true

require "bundler/setup"

require "bootsnap"
Bootsnap.setup(cache_dir: "tmp/cache")

Bundler.require(:default)

loader = Zeitwerk::Loader.for_gem

module App
  class Error < StandardError; end

  module T
    include Dry.Types

    StringLike = (Dry.Types::Strict::String | Dry.Types::Strict::Symbol).constructor(&:to_s)
    KV = Dry.Types::Strict::Hash.map(StringLike, Dry.Types::Strict::String)
  end

  def self.included(base)
    base.include(Async::App::Component)
    base.include(Memery)
  end
end

loader.setup
loader.eager_load
