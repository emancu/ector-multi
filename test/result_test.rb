# frozen_string_literal: true

require_relative 'helper'

Protest.describe 'Ector::Multi::Result' do
  test 'attribute readers' do
    results = { operation: 1, procedure: 2 }
    error = Ector::Multi::Rollback.new
    result = Ector::Multi::Result.new(results, error)

    assert_equal result.results, results
    assert_equal result.error, error
  end

  context 'succcess?' do
    test 'returns `true` when it succeeded' do
      result = Ector::Multi::Result.new({})

      assert result.success?
    end

    test 'returns `false` when there is an error' do
      result = Ector::Multi::Result.new({}, Ector::Multi::Rollback.new)

      refute result.success?
    end
  end

  context 'failure?' do
    test 'returns `true` when it failed' do
      result = Ector::Multi::Result.new({}, Ector::Multi::Rollback.new)

      assert result.failure?
    end

    test 'returns `false` when there is no error' do
      result = Ector::Multi::Result.new({})

      refute result.failure?
    end
  end
end
