# frozen_string_literal: true

# TODO: better name
module App
  class Counter
    module HashDigPatch
      refine Hash do
        def dig!(*keys) = keys.reduce(self) { _1.fetch(_2) }
      end
    end

    using HashDigPatch

    def initialize
      @state = {}
    end

    def include?(key) = @state.key?(key)
    def counter(key) = @state.dig!(key, :counter)

    # Only payload of the first add is stored
    def add(key, payload = nil)
      item = @state[key] ||= { counter: 0, payload: }
      item[:counter] += 1
    end

    def get(key) = @state.dig!(key, :payload)

    def remove(key)
      payload = get(key)
      @state[key][:counter] -= 1
      return unless counter(key).zero?

      @state.delete(key)
      payload
    end
  end
end
