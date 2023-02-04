# frozen_string_literal: true

class Kubezilla::Docker::Registries::Ghcr < Kubezilla::Docker::Registries::Registry
  include Memery

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
