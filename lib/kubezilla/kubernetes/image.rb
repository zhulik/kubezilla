# frozen_string_literal: true

class Kubezilla::Kubernetes::Image
  include Memery

  attr_reader :json, :image, :name, :tag, :registry, :owner, :repo, :digest, :pod

  def initialize(json, pod:)
    @json = json
    @pod = pod

    @image = json["image"]
    @name, @tag = image.split(":")
    @registry, @owner, @repo = @name.split("/")
    @digest = json["imageID"].split("@").last
  end

  def hash
    image.hash
  end

  def ==(other)
    image == other.image
  end

  def eql?(other)
    image == other.image
  end
end
