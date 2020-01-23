# ActiveRecord::NestedAttributesDestroyIf

Adds a `:destroy_if` option to `.accepts_nested_attributes_for`, which is basically a stronger version of `:reject_if` that also destroys existing records.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_record-nested_attributes-destroy_if'
```

And then execute:

    $ bundle

## Usage

Use the `destroy_if` option when `reject_if` isn't strong enough, i.e. you want to also destroy existing records that pass the test, not just reject new records.

```ruby
class Parent < ActiveRecord::Base
  has_many :children
  accepts_nested_attributes_for :children, destroy_if: proc { |attrs| attrs["name"].blank? }
end

class Child < ActiveRecord::Base
  belongs_to :parent
end

tywin = Parent.create!(id: 1, name: "Tywin")
Child.create!(id: 1, parent_id: 1, name: "Jaime")
Child.create!(id: 2, parent_id: 1, name: "Tyrion")

tywin.children # => [<Child id: 1, parent_id: 1, name: "Jaime">, <Child id: 2, parent_id: 1, name: "Tyrion">]

tywin.update!({
  children_attributes: {
    "0" => {
      id: 1,
      name: "Ser Jaime",
    },
    "1" => {
      id: 2,
      name: "",
    },
  },
})

tywin.children # => [<Child id: 1, parent_id: 1, name: "Ser Jaime">]

Child.find(2) # => raises ActiveRecord::RecordNotFound! Tyrion was destroyed!
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/botandrose/active_record-nested_attributes-destroy_if.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
