# frozen_string_literal: true

class Kubezilla::Docker::Registries::Docker < Kubezilla::Docker::Registries::Registry
  def needs_update?
    false
  end
end
