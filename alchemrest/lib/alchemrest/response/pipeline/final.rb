# frozen_string_literal: true

module Alchemrest
  class Response
    class Pipeline
      class Final
        include Concord::Public.new(:value)
      end
    end
  end
end
