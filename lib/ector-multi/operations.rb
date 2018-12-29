# frozen_string_literal: true

module Ector
  class Multi
    module Operation
      class Base
        attr_reader :name

        def initialize(name, block)
          @name = name
          @block = block
        end

        def inspect
          "#<#{self.class.name} #{@name}>"
        end

        def run(results)
          output = @block.(results)

          perform(output)
        rescue Ector::Multi::Rollback => error
          raise Ector::Multi::OperationFailure.new(self, output, error)
        end

        def fail_fast?
          self.is_a?(Ector::Multi::Operation::Error)
        end

        private

        def perform(_output)
          raise NotImplemented
        end
      end

      class Create < Base
        def initialize(name, model, attributes_block)
          @model = model
          super(name, attributes_block)
        end

        private

        def perform(attributes)
          @model.create!(attributes)
        end
      end

      class Update < Base
        def initialize(name, instance, attributes_block)
          @instance = instance
          super(name, attributes_block)
        end

        private

        def perform(attributes)
          @instance.update!(attributes)

          @instance
        end
      end

      class UpdateAll < Base
        def initialize(name, dataset, attributes_block)
          @dataset = dataset
          super(name, attributes_block)
        end

        private

        def perform(attributes)
          @dataset.update_all(attributes)
        end
      end

      class Destroy < Base
        private

        def perform(model)
          model.destroy
        end
      end

      class DestroyAll < Base
        private

        def perform(dataset)
          dataset.destroy_all
        end
      end

      class Lambda < Base
        private

        def perform(block_output)
          block_output
        end
      end

      class Error < Base
        def run(results)
          output = @block.(results)

          raise Ector::Multi::ControlledFailure.new(self, output)
        end
      end
    end
  end
end
