# frozen_string_literal: true

class Kubezilla::Docker::Registries::Docker < Kubezilla::Docker::Registries::Registry
  include Memery

  # TODO: support for other archs
  def needs_update?(image)
    body = connection.get("/v2/namespaces/#{image.owner}/repositories/#{image.repo}/tags/#{image.tag}").body
    manifests = JSON.parse(body)
    last_digest = manifests["images"].find { _1["architecture"] == "amd64" }["digest"]

    return last_digest if last_digest != image.digest
  end

  private

  def connection
    Faraday.new("https://hub.docker.com") do |f|
      f.response :raise_error
    end
  end
end
