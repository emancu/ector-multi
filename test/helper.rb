# frozen_string_literal: true

# Protest
require 'protest'

Protest.report_with(:progress)

def refute(condition, message="Expected condition to be unsatisfied")
  assert !condition, message
end

# ActiveRecord
require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Schema.verbose = false
# ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Migration.create_table :dummies, force: true do |t|
  t.integer :user_id
  t.string :name
end

class Dummy < ActiveRecord::Base; end

# Load lib

require_relative '../lib/ector-multi.rb'
