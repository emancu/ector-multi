# frozen_string_literal: true

require_relative 'helper'

Protest.describe 'Ector::Multi' do
  setup do
    Dummy.delete_all
    @multi = Ector::Multi.new
  end

  context '#append' do
    setup do
      @left_multi = @multi.run(:left) { |_| }
    end

    test 'adds operations to the end of the queue' do
      right_multi =
        Ector::Multi.new
        .run(:right) { |_| }
        .run(:far_right) { |_| }

      @left_multi.append(right_multi)

      assert_equal @left_multi.to_list, [:left, :right, :far_right]
    end

    test 'nothing changes when appends an empty multi' do
      @left_multi.append(Ector::Multi.new)

      assert_equal @left_multi.to_list, [:left]
    end

    test 'fails when there are duplicated operations' do
      duplicated_multi =
        Ector::Multi.new
        .run(:should_fail) { |_| }
        .run(:left) { |_| }

      assert_raise(Ector::Multi::UniqueOperationError) { @left_multi.append(duplicated_multi) }
      assert_equal @left_multi.to_list, [:left]
    end

    test 'returns self' do
      right_multi = Ector::Multi.new.run(:right) { |_| }

      returned = @left_multi.append(right_multi)

      assert_equal @left_multi, returned
    end
  end

  context '#create' do
    test 'adds a Create operation to the queue' do
      @multi.create(:dummy, Dummy, id: 1)

      assert_equal @multi.to_list, [:dummy]
      assert_equal @multi.operations.first.class, Ector::Multi::Operation::Create
    end

    test 'fails when the operation name exists' do
      @multi.run(:operation) { |_| }

      assert_raise(Ector::Multi::UniqueOperationError) { @multi.create(:operation, Dummy, id: 1) }
    end

    test 'does not create an instance yet' do
      @multi.create(:dummy, Dummy, name: 'New one')

      assert_equal Dummy.count, 0
    end

    test 'returns self' do
      assert_equal @multi, @multi.create(:dummy, Dummy, id: 1)
    end
  end

  context '#destroy' do
    setup do
      @instance = Dummy.create(name: 'Destroyable')
    end

    test 'adds a Delete operation to the queue' do
      @multi.destroy(:destroy_object, @instance)

      assert_equal @multi.to_list, [:destroy_object]
      assert_equal @multi.operations.first.class, Ector::Multi::Operation::Destroy
    end

    test 'fails when the operation name exists' do
      @multi.run(:operation) { |_| }

      assert_raise(Ector::Multi::UniqueOperationError) { @multi.destroy(:operation, @instance) }
    end

    test 'does not delete the instance yet' do
      @multi.destroy(:destroy_object, @instance)

      assert Dummy.find(@instance.id)
    end

    test 'returns self' do
      assert_equal @multi, @multi.destroy(:dummy, @instance)
    end
  end

  context '#destroy_all' do
    setup do
      Dummy.create(name: 'Destroyable')
    end

    test 'adds a Delete operation to the queue' do
      @multi.destroy_all(:destroy_object, Dummy)

      assert_equal @multi.to_list, [:destroy_object]
      assert_equal @multi.operations.first.class, Ector::Multi::Operation::DestroyAll
    end

    test 'fails when the operation name exists' do
      @multi.run(:operation) { |_| }

      assert_raise(Ector::Multi::UniqueOperationError) { @multi.destroy(:operation, @instance) }
    end

    test 'does not delete the instance yet' do
      @multi.destroy(:destroy_object, @instance)

      assert Dummy.count, 1
    end

    test 'returns self' do
      assert_equal @multi, @multi.destroy_all(:dummy, Dummy)
    end
  end

  context '#error' do
    test 'adds an Error operation to the queue' do
      @multi.error(:fail_fast, 1)

      assert_equal @multi.to_list, [:fail_fast]
      assert_equal @multi.operations.first.class, Ector::Multi::Operation::Error
    end

    test 'fails when the operation name exists' do
      @multi.run(:operation) { |_| }

      assert_raise(Ector::Multi::UniqueOperationError) { @multi.error(:operation, 1) }
    end

    test 'returns self' do
      assert_equal @multi, @multi.error(:dummy, 1)
    end
  end

  context '#prepend' do
    setup do
      @left_multi = @multi.run(:left) { }
    end

    test 'adds operations to the beginning of the queue' do
      right_multi =
        Ector::Multi.new
        .run(:right) { }
        .run(:far_right) { }

      @left_multi.prepend(right_multi)

      assert_equal @left_multi.to_list, [:right, :far_right, :left]
    end

    test 'nothing changes when prepends an empty multi' do
      @left_multi.prepend(Ector::Multi.new)

      assert_equal @left_multi.to_list, [:left]
    end

    test 'fails when there are duplicated operations' do
      duplicated_multi =
        Ector::Multi.new
        .run(:should_fail) { }
        .run(:left) { }

      assert_raise(Ector::Multi::UniqueOperationError) { @left_multi.prepend(duplicated_multi) }
      assert_equal @left_multi.to_list, [:left]
    end

    test 'returns self' do
      right_multi = Ector::Multi.new.run(:right) { }

      returned = @left_multi.prepend(right_multi)

      assert_equal @left_multi, returned
    end
  end

  context '#run' do
    test 'adds an Lambda operation to the queue' do
      @multi.run(:procedure) { |results| results }

      operation = @multi.operations.first
      assert_equal @multi.to_list, [:procedure]
      assert_equal operation.class, Ector::Multi::Operation::Lambda
    end

    test 'fails when the operation name exists' do
      @multi.run(:operation) { }

      assert_raise(Ector::Multi::UniqueOperationError) { @multi.run(:operation) { |_| 1 } }
    end

    test 'does not run the block yet' do
      call_counter = 0

      @multi.run(:procedure) { call_counter += 1 }

      assert_equal call_counter, 0
    end

    test 'returns self' do
      assert_equal(@multi, @multi.run(:dummy ) { })
    end
  end

  context '#update' do
    setup do
      @instance = Dummy.create(name: 'Original')
    end

    test 'adds an Update operation to the queue' do
      @multi.update(:change_name, @instance, name: 'Updated')

      operation = @multi.operations.first
      assert_equal @multi.to_list, [:change_name]
      assert_equal operation.class, Ector::Multi::Operation::Update
    end

    test 'fails when the operation name exists' do
      @multi.run(:operation) { |_| }

      assert_raise(Ector::Multi::UniqueOperationError) { @multi.update(:operation, @instance, id: 1) }
    end

    test 'does not update the instance yet' do
      @multi.update(:change_name, @instance, name: 'Updated')

      assert_equal @instance.reload.name, 'Original'
    end

    test 'returns self' do
      assert_equal @multi, @multi.update(:dummy, @instance, name: 'asd')
    end
  end

  context '#update_all' do
    setup do
      @instance = Dummy.create(name: 'Original')
    end

    test 'adds an UpdateAll operation to the queue' do
      @multi.update_all(:change_name, Dummy, name: 'Updated')

      operation = @multi.operations.first
      assert_equal @multi.to_list, [:change_name]
      assert_equal operation.class, Ector::Multi::Operation::UpdateAll
    end

    test 'fails when the operation name exists' do
      @multi.run(:operation) { |_| }

      assert_raise(Ector::Multi::UniqueOperationError) { @multi.update(:operation, @instance, id: 1) }
    end

    test 'does not update the instance yet' do
      @multi.update_all(:change_name, Dummy, name: 'Updated')

      assert_equal @instance.reload.name, 'Original'
    end

    test 'returns self' do
      assert_equal @multi, @multi.update_all(:dummy, Dummy, name: 'asd')
    end
  end

  context '#commit' do
    test 'trap Ector::Multi::Rollback exceptions' do
      @multi.run(:fail_gracefully) { fail Ector::Multi::Rollback.new 'handled' }

      result = @multi.commit

      assert result.failure?
      assert result.error.caused_by.is_a?(Ector::Multi::Rollback)
    end

    test 'raises any exception that is not a Ector::Multi::Rollback' do
      @multi.run(:fail_violently) { fail 'unhandled' }

      assert_raise(StandardError) { @multi.commit }
    end

    test 'stops execution immediately when an exception occurs' do
      @multi
      .run(:op1) { :should_pass }
      .run(:op2) { fail Ector::Multi::Rollback.new 'sorry' }
      .run(:op3) { :never_gets_called }

      result = @multi.commit

      assert result.failure?
      assert_equal result.results.keys, [:op1]
      assert_equal result.error.operation.name, :op2
    end

    test 'fails immediately when an Error Operation is enqueued' do
      @multi
      .run(:op1) { :never_gets_called }
      .run(:op2) { :never_gets_called }
      .run(:op3) { :never_gets_called }
      .error(:fail_fast, 1)

      result = @multi.commit

      assert result.failure?
      assert result.results.empty?
      assert_equal result.error.value, 1
      assert_equal result.error.operation.name, :fail_fast
    end

    test 'creates a transaction for each operation' do
      transaction_ids =
        @multi
        .run(:op1) { ActiveRecord::Base.connection.current_transaction.__id__ }
        .run(:op2) { ActiveRecord::Base.connection.current_transaction.__id__ }
        .run(:op3) { ActiveRecord::Base.connection.current_transaction.__id__ }
        .commit
        .results
        .values
        .uniq

      assert_equal transaction_ids.size, 3
    end

    test 'changes are persisted on success' do
      instance = Dummy.create(name: 'Original')
      deletable = Dummy.create(name: 'Deletable')

      result =
        @multi
        .create(:new_dummy, Dummy, name: 'From multi')
        .update(:rename, instance, name: 'Updated')
        .destroy(:remove, deletable)
        .commit

      assert result.success?
      assert_equal Dummy.all.map(&:name), ['Updated', 'From multi']
      assert_equal result.results.keys, [:new_dummy, :rename, :remove]
    end

    test 'changes are rolledback on failure' do
      instance = Dummy.create(name: 'Original')
      deletable = Dummy.create(name: 'Deletable')

      result =
        @multi
        .create(:new_dummy, Dummy, name: 'From multi')
        .update(:rename, instance, name: 'Updated')
        .destroy(:remove, deletable)
        .run(:force_failure) { fail Ector::Multi::Rollback.new('abort')}
        .commit

      assert result.failure?
      assert_equal Dummy.all.map(&:name), ['Original', 'Deletable']
      assert_equal result.results.keys, [:new_dummy, :rename, :remove]
      assert_equal result.error.operation.name, :force_failure
    end

    test 'returns a Ector::Multi::Result' do
      assert @multi.commit.is_a?(Ector::Multi::Result)
    end
  end

  context '#to_list' do
    test 'returns an ordered list with the name of the operations' do
      nop = -> { }
      empty = @multi
      single = Ector::Multi.new.run(:lambda, &nop)
      multi = Ector::Multi.new.run(:annonymous, &nop).run(:operations, &nop)

      assert_equal empty.to_list, []
      assert_equal single.to_list, [:lambda]
      assert_equal multi.to_list, [:annonymous, :operations]
    end
  end
end
