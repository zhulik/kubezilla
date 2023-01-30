# frozen_string_literal: true

require "zilla"
require "memery"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem

class Kubezilla::Error < StandardError
  # Your code goes here...
end

loader.setup
loader.eager_load
