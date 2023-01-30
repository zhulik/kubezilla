# frozen_string_literal: true

class Kubezilla::Docker::Registries::Registry
  include Memery

  memoize def needs_update?(image) = raise(NotImplementedError)
end
