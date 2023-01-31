# frozen_string_literal: true

class Kubezilla::Kubernetes::Client
  include Kubezilla::Kubernetes
  include Memery
  include Kubezilla::Logger

  INPUT = "#{__dir__}/../../../data/swagger.json".freeze

  SERVICE_ACCOUNT_PATH = "/var/run/secrets/kubernetes.io/serviceaccount"
  TOKEN_PATH = "#{SERVICE_ACCOUNT_PATH}/token".freeze
  CERT_PATH = "#{SERVICE_ACCOUNT_PATH}/ca.crt".freeze

  # TODO: CronJob, DaemonSet
  APP_TYPES = ["Deployment", "StatefulSet"].freeze

  attr_reader :host, :scheme, :block

  def initialize(host:, scheme:, &block)
    @host = host
    @scheme = scheme

    @block = block
  end

  memoize def client
    token
    Zilla.for(INPUT, host:, scheme:) do |f, target|
      f.adapter :async_http
      @block.call(f, target) if @block
    end
  end

  def applications
    APP_TYPES.map do |type|
      Async do
        client.send("listAppsV1#{type}ForAllNamespaces")["items"].map do |item|
          Application.new(type, item, client: self)
        end
      end
    end.flat_map(&:wait)
  end

  def method_missing(method_name, *, **, &) = client.send(method_name, *, **, &)

  def respond_to_missing?(method_name, include_private = false)
    client.respond_to_missing?(method_name, include_private)
  end

  def token
    File.read(TOKEN_PATH)
  rescue Errno::ENOENT
    warn { "ServiceAccount token file #{TOKEN_PATH} was not found. Not running in kubernetes?" }
  end
end
