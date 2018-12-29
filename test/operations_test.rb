# frozen_string_literal: true

require_relative 'helper'

Protest.describe 'Operations' do
  setup do
    Dummy.delete_all
  end

  context 'Create' do
    setup do
      @op = Ector::Multi::Operation::Create.new(:t, Dummy, lambda { |results| { name: 'Emi' }.merge(results) } )
    end

    test 'it does not fail fast' do
      refute @op.fail_fast?
    end

    test 'raises an exception when creation fails' do
      assert_raise(StandardError) do
        @op.run(unknown_attribute: 123)
      end

      assert_equal Dummy.count, 0
    end

    test 'returns the object created' do
      res = @op.run(name: 'Created')

      assert_equal res.class, Dummy
      assert_equal res.name, 'Created'
      assert_equal res.id, Dummy.last.id
    end
  end

  context 'Update' do
    setup do
      @instance = Dummy.create(name: 'Original')
      @op = Ector::Multi::Operation::Update.new(:t, @instance, lambda { |results| { name: 'Updated' }.merge(results) } )
    end

    test 'it does not fail fast' do
      refute @op.fail_fast?
    end

    test 'raises an exception when update fails' do
      assert_raise(StandardError) do
        @op.run(unknown_attribute: 123)
      end

      assert_equal @instance.reload.name, 'Original'
    end

    test 'returns the object created' do
      res = @op.run(name: 'Updated baby')

      assert_equal res.class, Dummy
      assert_equal res.name, 'Updated baby'
      assert_equal res.id, @instance.id
    end
  end

  context 'UpdateAll' do
    setup do
      @instance = Dummy.create(name: 'Original')
      @op = Ector::Multi::Operation::UpdateAll.new(:t, Dummy, lambda { |results| { name: 'Updated' }.merge(results) } )
    end

    test 'it does not fail fast' do
      refute @op.fail_fast?
    end

    test 'raises an exception when update fails' do
      assert_raise(StandardError) do
        @op.run(unknown_attribute: 123)
      end

      assert_equal @instance.reload.name, 'Original'
    end

    test 'returns how many records were updated' do
      res = @op.run(name: 'Mass update')

      assert_equal res, 1
      assert_equal @instance.reload.name, 'Mass update'
    end

    test 'accepts a dataset' do
      Dummy.create(name: 'original 2')
      Dummy.create(name: 'original 3')

      @op = Ector::Multi::Operation::UpdateAll.new(:t, Dummy.where.not(name: 'original 2'), lambda { |results| results } )
      res = @op.run(name: 'MassUpdated')

      assert_equal res, 2
      assert_equal Dummy.count, 3
      assert_equal Dummy.all.map(&:name), ['MassUpdated', 'original 2', 'MassUpdated']
    end
  end

  context 'Destroy' do
    setup do
      @instance = Dummy.create(name: 'Original')
      @op = Ector::Multi::Operation::Destroy.new(:t, lambda { |_| @instance } )
    end

    test 'it does not fail fast' do
      refute @op.fail_fast?
    end

    test 'returns the object destroyed' do
      res = @op.run({})

      assert res.frozen?
      assert_equal res.class, Dummy
      assert_equal res.id, @instance.id
    end
  end

  context 'DestroyAll' do
    setup do
      @instance = Dummy.create(name: 'Original')
      @op = Ector::Multi::Operation::DestroyAll.new(:t, lambda { |_| Dummy })
    end

    test 'it does not fail fast' do
      refute @op.fail_fast?
    end

    test 'returns a list of instances destroyed' do
      res = @op.run(destroy: 'all')

      assert_equal res, [@instance]
      assert_equal Dummy.count, 0
      assert_raise(ActiveRecord::RecordNotFound) { @instance.reload }
    end

    test 'accepts a dataset' do
      Dummy.create(name: 'original 2')
      Dummy.create(name: 'original 3')

      @op = Ector::Multi::Operation::DestroyAll.new(:t, lambda { |_| Dummy.where.not(name: 'original 2') } )
      res = @op.run(destroy: 'with where')

      assert_equal res.map(&:name), ['Original', 'original 3']
      assert_equal Dummy.count, 1
      assert_equal Dummy.all.map(&:name), ['original 2']
    end
  end

  context 'Lambda' do
    setup do
      @lambda = Proc.new { [true, 1] }
      @op = Ector::Multi::Operation::Lambda.new(:t, @lambda )
    end

    test 'it does not fail fast' do
      refute @op.fail_fast?
    end

    test 'returns the return value of the block' do
      res = @op.run({})

      assert_equal res, [true, 1]
      assert_equal res, @lambda.call
    end
  end

  context 'Error' do
    setup do
      @op = Ector::Multi::Operation::Error.new(:t, lambda { |r| 1} )
    end

    test 'it does not fail fast' do
      assert @op.fail_fast?
    end

    test 'returns the return value of the block' do
      assert_raise(Ector::Multi::ControlledFailure) { @op.run({}) }
    end
  end
end
