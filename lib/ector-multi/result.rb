# frozen_string_literal: true

module Ector
  class Multi
    class Result
      attr_reader :results, :error

      def initialize(results, error = nil)
        @results = results
        @error = error
      end

      def success?
        !@error
      end

      def failure?
        !success?
      end
    end
  end
end
