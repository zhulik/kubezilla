# frozen_string_literal: true

class Kubezilla::Docker::Registries::Docker < Kubezilla::Docker::Registries::Registry
  include Memery

  private

  def connection
    Faraday.new("https://registry-1.docker.io") do |f|
      f.response :raise_error
    end
  end

  def token_connection
    Faraday.new("https://auth.docker.io") do |f|
      f.response :raise_error
    end
  end

  def token(name)
    JSON.parse(token_connection.get("token?service=registry.docker.io&scope=repository:#{name}:pull").body)["token"]
  end
end
