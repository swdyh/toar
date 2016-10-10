# Toar

# Deserialize ActiveRecord Model JSON (to_json -> to_ar)
## Installation

Add this line to your application's Gemfile:

```ruby
gem 'toar'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install toar

## Usage

```
> user = User.create(name: 'A')
=> #<User id: 1, name: "A", account_id: nil>

> user.posts.create(body: 'Post1')
=> #<Post id: 1, user_id: 1, body: "Post1">

> user.posts.create(body: 'Post2')
=> #<Post id: 2, user_id: 1, body: "Post2">

> user.create_account(name: 'AC')
=> #<Account id: 1, name: "AC">

> json = user.to_json(include: [:posts, :account])
=> "{\"id\":1,\"name\":\"A\",\"account_id\":1,\"posts\":[{\"id\":1,\"user_id\":1,\"body\":\"Post1\"},{\"id\":2,\"user_id\":1,\"body\":\"Post2\"}],\"account\":{\"id\":1,\"name\":\"AC\"}}"

> [Post, User, Account].each(&:destroy_all)
=> [Post(id: integer, user_id: integer, body: text), User(id: integer, name: string, account_id: integer), Account(id: integer, name: string)]

> user_r = Toar.to_ar(User, json)
=> #<User id: 1, name: "A", account_id: nil>

> user_r.posts
=> #<ActiveRecord::Associations::CollectionProxy [#<Post id: 1, user_id: 1, body: "Post1">, #<Post id: 2, user_id: 1, body: "Post2">]>

> user_r.account
=> #<Account id: 1, name: "AC">
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
