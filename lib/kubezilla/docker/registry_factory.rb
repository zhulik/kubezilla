# frozen_string_literal: true

module Kubezilla::Docker::RegistryFactory
  include Kubezilla::Docker

  REGISTRIES = {
    "docker.io" => Registries::Docker.new,
    "ghcr.io" => Registries::Ghcr.new
  }.freeze

  def self.for(registry)
    REGISTRIES[registry].tap do |reg|
      raise ArgumentError, "registry #{registry} is unknown" if reg.nil?
    end
  end
end
