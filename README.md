# Ector::Multi
[![Gem Version](https://badge.fury.io/rb/ector-multi.svg)](http://badge.fury.io/rb/ector-multi)
[![Build Status](https://travis-ci.org/emancu/ector-multi.svg)](https://travis-ci.org/emancu/ector-multi)
[![Code Climate](https://codeclimate.com/github/emancu/ector-multi/badges/gpa.svg)](https://codeclimate.com/github/emancu/ector-multi)
[![RubyGem](https://img.shields.io/gem/dt/ector-multi.svg)](https://rubygems.org/gems/ector-multi)

`Ector::Multi` is an object for grouping multiple DB operations that should be performed in a single database transaction.

I literally copy the API and idea from [Ecto::Multi](https://hexdocs.pm/ecto/Ecto.Multi.html), so I'm gonna copy the documentation as well.

## Dependencies

At this moment, `Ector::Multi` requires `ActiveRecord` as a dependency and relies on it for CRUD operations and transactions.
Eventually, I would like to be ORM-agnostic and be able to configure different ORMs and remove the hard dependency.

## Getting started

`Ector::Multi` is an object for grouping multiple database operations.

`Ector::Multi` makes it possible to pack operations that should be performed in a single database transaction and gives a way to introspect the queued operations without actually performing them. Each operation is given a name that is unique and will identify its result in case of success or failure.

All operations will be executed in the order they were added.

The `Ector::Multi` object should be considered opaque. You can use common ruby techniques to dig into it, but accessing fields or directly modifying them is not advised.


## Run

`Ector::Multi` allows you to run arbitrary functions as part of your transaction via `run`.
This is especially useful when an operation depends on the value of a previous operation.
For this reason, the function given as a callback to run will receive all changes performed by the multi so far.

The function given to `run` must return _something_ or raise a `Ector::Multi::OperationFailure`. Raising an error will abort any further operations and make the whole multi fail.

## Example

Let’s look at an example definition and usage. The use case we’ll be looking into is resetting a password.
We need to update the account with proper information, log the request and remove all current sessions:

```ruby
module PasswordManager
  def self.reset(account, params)
    Ector::Multi.new
    .update(:account, account, params)
    .create(:log, Log, account_id: account.id, changed_at: Time.now)
    .destroy_all(:clear_sessions, Session.where(account_id: account.id))
  end
end
```

We can later execute it in the integration layer using `#commit`:

```ruby
  result = PasswordManager.reset(account, params).commit
```

The resulting object, a `Ector::Multi::Result`, will tell you if it succeeded or failed. Also, it is possible to dig into the results of each operation.

## Functions

`multi.append(second_mutli)`

Appends the second multi to the first one

`multi.destroy(name, instance)`

Adds a destroy operation to the multi

`multi.destroy_all(name, queryable)`

Adds a destroy_all operation to the multi

`multi.error(name, value)`

Causes the multi to fail with the given value

`multi.create(name, model, attributes, &block = nil)`

Adds a create operation to the multi

`Ector::Multi.new`

Returns an empty Ector::Multi object

`multi.prepend(second_multi)`

Prepends the second multi to the first one

`multi.run(name, &run)`

Adds a function to run as part of the multi

`multi.to_list`

Returns the list of operations stored in multi

`multi.update(name, instance, updates, &block = nil)`

Adds an update operation to the multi

`multi.update_all(name, queryable, updates, &block = nil)`

Adds an update_all operation to the multi
