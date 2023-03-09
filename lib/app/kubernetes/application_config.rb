# frozen_string_literal: true

class App::Kubernetes::ApplicationConfig < Dry::Struct
  include App

  attribute :enabled, T::Params::Bool

  attribute?(:polling_interval, T::Strict::Float.default(300.0).constructor do |arg|
    arg == Dry::Core::Undefined ? arg : App::IntervalParser.parse(arg)
  end)

  def self.for(application)
    new(**application.metadata
                     .annotations
                     .select { _1.start_with?("kubezilla") }
                     .transform_keys { _1[10..].to_sym })
  end

  def enabled? = enabled
end
