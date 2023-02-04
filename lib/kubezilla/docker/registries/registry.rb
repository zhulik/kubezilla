# frozen_string_literal: true

class Kubezilla::Docker::Registries::Registry
  include Memery

  # TODO: support for other archs
  def published_digest(image)
    body = connection.get("/v2/#{image.name}/manifests/#{image.tag}", {},
                          { Authorization: "Bearer #{token(image.name)}",
                            Accept: "application/vnd.docker.distribution.manifest.v2+json" }).body

    manifests = JSON.parse(body)

    digest = manifests.dig("config", "digest")
    return digest if digest

    manifests["manifests"].find { _1["platform"]["architecture"] == "amd64" }["digest"]
  end
end
