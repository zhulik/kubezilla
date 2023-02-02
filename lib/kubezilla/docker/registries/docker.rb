# frozen_string_literal: true

class Kubezilla::Docker::Registries::Docker < Kubezilla::Docker::Registries::Registry
  include Memery

  # TODO: support for other archs
  def published_digest(image)
    body = connection.get("/v2/namespaces/#{image.owner}/repositories/#{image.repo}/tags/#{image.tag}").body

    manifests = JSON.parse(body)
    manifests["images"].find { _1["architecture"] == "amd64" }["digest"]
  end

  private

  def connection
    Faraday.new("https://hub.docker.com") do |f|
      f.response :raise_error
    end
  end
end
