# frozen_string_literal: true

class Kubezilla::Kubernetes::Image
  include Memery

  attr_reader :json, :image, :full_name, :tag, :registry, :owner, :repo, :digest

  def initialize(json)
    @json = json

    @image = json["image"]
    @name, @tag = image.split(":")
    @registry, @owner, @repo = @name.split("/")
    @digest = json["imageID"].split("@").last
  end

  memoize def name = "#{@owner}/#{@repo}"

  def hash = image.hash
  def ==(other) = image == other.image
  def eql?(other) = image == other.image
end
