# frozen_string_literal: true

class Kubezilla::Client
  include Memery

  INPUT = "#{__dir__}/../../data/swagger.json".freeze

  attr_reader :host, :scheme, :block

  def initialize(host:, scheme:, &block)
    @host = host
    @scheme = scheme
    @block = block
  end

  memoize def client = Zilla.for(INPUT, host:, scheme:, &block)

  def method_missing(method_name, *, **, &) = client.send(method_name, *, **, &)

  def respond_to_missing?(method_name, include_private = false)
    client.respond_to_missing?(method_name, include_private)
  end
end
