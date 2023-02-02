# frozen_string_literal: true

class Kubezilla::Docker::Registries::Ghcr < Kubezilla::Docker::Registries::Registry
  include Memery

  # TODO: support for other archs
  def published_digest(image)
    body = connection.get("/v2/#{image.name}/manifests/#{image.tag}", {},
                          { Authorization: "Bearer #{token(image.name)}" }).body
    manifests = JSON.parse(body)

    digest = manifests.dig("config", "digest")
    return digest if digest

    manifests["manifests"].find { _1["platform"]["architecture"] == "amd64" }["digest"]
  end

  private

  def connection
    Faraday.new("https://ghcr.io") do |f|
      f.response :raise_error
    end
  end

  def token(name)
    JSON.parse(connection.get("token?scope=repository:#{name}:pull").body)["token"]
  end
end
