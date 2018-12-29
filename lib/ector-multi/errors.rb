# frozen_string_literal: true

module Ector
  class Multi
    # Parent class for all Multi errors
    Error = Class.new(StandardError)

    # Parent class for all "Rollback-able" errors
    Rollback = Class.new(Error)

    class OperationFailure < Rollback
      attr_reader :operation, :arguments, :caused_by
      alias_method :value, :arguments

      def initialize(operation, arguments, caused_by)
        @operation = operation
        @arguments = arguments
        @caused_by = caused_by

        super("Rollback fired by #{operation.name}")
      end

      def inspect
        "#<#{self.class.name} #{@operation.name} @caused_by=#{@caused_by.class} @arguments=#{@arguments}>"
      end
    end

    class ControlledFailure < OperationFailure
      def initialize(operation, value)
        super(operation, value, nil)
      end

      def inspect
        "#<#{self.class.name} #{@operation.name} value=#{@arguments}>"
      end
    end

    class UniqueOperationError < Error
      attr_reader :name

      def initialize(name)
        @name = name

        super("Operation name '#{name}' is not unique!")
      end
    end
  end
end
