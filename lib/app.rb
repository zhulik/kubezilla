# frozen_string_literal: true

require "bundler/setup"

require "bootsnap"
Bootsnap.setup(cache_dir: "tmp/cache")

Bundler.require(:default)

require "zilla/api_client"
require "zilla/api_error"
require "zilla/version"
require "zilla/configuration"

require "zilla/api/apps_v1_api"
require "zilla/api/core_v1_api"

# TODO: move to to zilla/kubernetes
def Zilla.const_missing(name)
  require "zilla/models/#{name.to_s.underscore}"
  Zilla.const_get(name)
end

require "zilla/kubernetes"

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
