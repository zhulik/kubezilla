# frozen_string_literal: true

module Kubezilla::Docker::RegistryFactory
  include Kubezilla::Docker

  REGISTRIES = {
    "docker.io" => Registries::Docker
  }.freeze

  def self.build(image)
    registry = REGISTRIES[image.registry]

    raise ArgumentError, "registry #{image.registry} is unknown" if registry.nil?

    registry.new(image)
  end
end
