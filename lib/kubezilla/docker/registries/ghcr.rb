# frozen_string_literal: true

class Kubezilla::Docker::Registries::Ghcr < Kubezilla::Docker::Registries::Registry
  include Memery

  # TODO: support for other archs
  def published_digest(image)
    body = connection.get("/v2/#{image.name}/manifests/#{image.tag}", {},
                          { Authorization: "Bearer #{token(image.name)}" }).body
    manifests = JSON.parse(body)
    return unless manifests.dig("config", "digest").nil?

    pp(image.name, manifests)

    # TODO: raise if not found
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
