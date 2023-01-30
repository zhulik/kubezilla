# frozen_string_literal: true

module Kubezilla::Logger
  [:debug, :info, :warn, :error, :fatal].each do |name|
    define_method(name) do |msg = nil, &block|
      Console.logger.public_send(name, self, msg, &block)
    end
  end
end
