# frozen_string_literal: true

class Kubezilla::Docker::Registries::Registry
  include Memery

  attr_reader :image

  def initialize(image)
    @image = image
  end

  memoize def needs_update? = raise(NotImplementedError)
end
