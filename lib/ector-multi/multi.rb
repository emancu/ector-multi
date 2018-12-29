# frozen_string_literal: true

module Ector
  class Multi
    attr_reader :failure, :results, :operations

    def initialize
      @operations = []
    end

    def append(multi)
      check_operation_uniqueness!(multi.to_list)

      @operations.push *multi.operations

      self
    end

    def create(name, model, attributes = {}, &block)
      add_operation Operation::Create.new(name, model, operation_block(attributes, block))
    end

    def destroy(name, object = nil, &block)
      add_operation Operation::Destroy.new(name, operation_block(object, block))
    end

    def destroy_all(name, dataset = nil, &block)
      add_operation Operation::DestroyAll.new(name, operation_block(dataset, block))
    end

    def error(name, value)
      add_operation Operation::Error.new(name, operation_block(value, nil))
    end

    def merge(multi)
      raise NotImplemented
    end

    def prepend(multi)
      check_operation_uniqueness!(multi.to_list)

      @operations.prepend *multi.operations

      self
    end

    def run(name, &procedure)
      add_operation Operation::Lambda.new(name, procedure)
    end

    def update(name, object, new_values, &block)
      add_operation Operation::Update.new(name, object, operation_block(new_values, block))
    end

    def update_all(name, dataset, new_values, &block)
      add_operation Operation::UpdateAll.new(name, dataset, operation_block(new_values, block))
    end

    def commit
      results = {}

      fail_fast = operations.find(&:fail_fast?)
      fail_fast.run(results) if fail_fast

      ::ActiveRecord::Base.transaction(joinable: false, requires_new: true) do
        operations.each do |operation|
          ::ActiveRecord::Base.transaction(joinable: false, requires_new: true) do
            results[operation.name] = operation.run(::OpenStruct.new(results))
          end
        end
      end

      Ector::Multi::Result.new(results)
    rescue Ector::Multi::Rollback => error
      Ector::Multi::Result.new(results, error)
    end

    def to_list
      operations.map(&:name)
    end

    private

    def add_operation(operation)
      check_operation_uniqueness!(operation.name)

      @operations << operation

      self
    end

    def check_operation_uniqueness!(names)
      repeated_names = to_list & Array(names)

      fail UniqueOperationError.new(repeated_names) if repeated_names.any?
    end

    def operation_block(args, block)
      if block
        Proc.new { |results| block.(results, args) }
      else
        Proc.new { |_| args }
      end
    end
  end
end
