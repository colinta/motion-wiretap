Wiretap
-------

An iOS / OS X wrapper heavily inspired by ReactiveCocoa.

    gem install motion-wiretap

Run the OSX specs using `rake spec platform=osx`

First things first
------------------

You **MUST** call `cancel!` on any wiretaps you create, otherwise they will live
in memory forever.  The upside is that you can create 

Showdown
--------

Open these side by side to see the comparison:

[reactive.rb](https://gist.github.com/colinta/d0a273f8d858a8f61c73)
[reactive.mm](https://gist.github.com/colinta/5cfa588fed7b929193ae)

Usage
-----

These are taken from the specs.

### Key-Value Observation

```ruby
class Person
  attr_accessor :name
  attr_accessor :email
  attr_accessor :address
end

# listen for changes
person = Person.new
person.wiretap(:name) do |name|
  puts "name is now #{name}"
end
person.name = 'Joe'
# puts => "name is now Joe"

# bind the property of one object to the value of another
person_1 = Person.new
person_2 = Person.new
wiretap = person_1.wiretap(:name).bind_to(person_2.wiretap(:name))
person_2.name = 'Bob'
person_1.name # => "Bob"

# cancel a wiretap
wiretap.cancel!
person_2.name = 'Jane'
person_1.name
# => "BOB"

# bind the property of one object to the value of another, but change it using `map`
wiretap = person_1.wiretap(:name).bind_to(person_2.wiretap(:name).map { |value| value.upcase })
person_2.name = 'Bob'
person_1.name # => "BOB"
```

### Working with arrays

```
# combine the values `name` and `email`
person = Person.new
[
  person.wiretap(:name),
  person.wiretap(:email),
].wiretap.combine do |name, email|
  puts "#{name} <#{email}>"
end

person.name = 'Kazuo'
# puts => "Kazuo <>"
person.email = 'kaz@example.com'
# puts => "Kazuo <kaz@example.com>"

# reduce/inject
person_1 = Person.new
person_2 = Person.new
[
  person_1.wiretap(:name),
  person_2.wiretap(:name),
].wiretap.reduce do |memo, name|
  memo ||= []
  memo + [name]
end
person_1.name = 'Mr. White'
person_1.name = 'Mr. Blue'
# => ['Mr. White', 'Mr. Blue']

# you can provide an initial 'memo' (default: nil)
[
  person_1.wiretap(:name),
  person_2.wiretap(:name),
].wiretap.reduce([]) do |memo, name|
  memo + [name]  # you should not change memo in place, the same one will be used on every change event
end
```

### Monitoring jobs

```ruby
# monitor for background job completion
-> {
  this_will_take_forever!
}.wiretap(Dispatch::Queue.concurrent) do
  puts "done!"
end

# Note: this is convenient shorthand for calling `queue`, `and_then`, and `start`
-> {}.wiretap.queue(...).and_then do ... end.start

# send a stream of values.  a lambda is passed in that will forward change
# events to the `listen` block
-> (on_change) do
  5.times do |count|
    on_change.call count
  end
end.wiretap.queue(Dispatch::Queue.concurrent).listen do |index|
  puts "...#{index}"
end.and_then do
  puts "done!"
end.start
# => puts "...0", "...1", "...2", "...3", "...4", "done!"
```

### Let's do something practical!

```ruby
# bind the `enabled` property to the Wiretap object to a check on whether
# `username_field.text` and `password_field.text` are blank
@login_button.wiretap(:enabled).bind_to(
  [
    @username_field.wiretap(:text),
    @password_field.wiretap(:text),
  ].wiretap.combine do |username, password|
    username && username.length > 0 && password && password.length > 0
  end
  )
```

### Notifications

```ruby
notification = "NotificationName".wiretap do
  puts "notification received!"
end

# rememder: it's *important* to cancel all wiretaps!
notification.cancel!
```