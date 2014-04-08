MotionWiretap
-------------

An iOS / OS X library heavily inspired by ReactiveCocoa.

    gem install motion-wiretap

Run the iOS specs using `rake spec`
Run the OSX specs using `rake spec platform=osx`

First things first
------------------

You **MUST** retain any wiretaps you create, otherwise they will be garbage
collected immediately.  I don't yet have a clever way to avoid this unfortunate
state of affairs, other than keeping some global list of wiretaps.  UG to that.

How does ReactiveCocoa do it, anyone know?  I'd love to mimic that.

This isn't a terrible thing, though, since most wiretaps require that you call
the `cancel!` method. Again, I'm not sure how ReactiveCocoa accomplishes the
"auto shutdown" of signals that rely on notifications and key-value observation.

Showdown
--------

Open these side by side to see the comparison:

[reactive.rb](https://gist.github.com/colinta/d0a273f8d858a8f61c73)
[reactive.mm](https://gist.github.com/colinta/5cfa588fed7b929193ae)

Usage
-----

Creating a wiretap is done using the factory method `Motion.wiretap()`, also
aliased as `MW()`.

```ruby
@wiretap = Motion.wiretap(obj, :property)  # this object will notify listeners everytime obj.property changes
@wiretap = MW(obj, :property)
```

If you want to use a more literate style, you can include the
`motion-wiretap-polluting` to have a `wiretap` method added to your objects. *I*
like this style, but the default is to have a non-polluting system.

```ruby
@wiretap = obj.wiretap(:property)
```

Wiretaps can be composed all sorts of ways: you can filter them, map them,
combine multiple wiretaps into a single value, use them to respond to
notifications or control events.

### Let's start with something practical!

In these examples I will use all three ways of creating a Wiretap
(`MW(), Motion.wiretap(), object.wiretap`).

```ruby
# assign the label to the text view; changes to the text view will be reflected
# on the label.
MW(@label, :text).bind_to(MW(@text_view, :text))

# assign the attributedText of the label to the text view, doing some
# highlighting in-between.
@label.wiretap(:attributedText).bind_to(@text_view.wiretap(:text).map do |text|
  NSAttributedString.alloc.initWithString(text, attributes: { NSForegroundColorAttributeName => UIColor.blueColor })
end)

# This code will set the 'enabled' property depending on whether the username
# and password are not empty.
Motion.wiretap(@login_button, :enabled).bind_to(
  Motion.wiretap([
    Motion.wiretap(@username_field, :text),
    Motion.wiretap(@password_field, :text),
  ]).combine do |username, password|
    # use motion-support to get the 'present?' method
    username.present? && password.present?
  end
  )
```

### Types of wiretaps

- Key-Value Observation / KVO
- Arrays (map/reduce/combine)
- Jobs (event stream, completion)
- UIView Gestures
- UIControl events
- NSNotificationCenter

### Key-Value Observation

```ruby
class Person
  attr_accessor :name
  attr_accessor :email
end

# listen for changes
person = Person.new
# you need to store the wiretap object in memory; when the object is
# deallocated, it will no longer receive updates.
wiretap = Motion.wiretap(person, :name)
# react to change events
wiretap.listen do |name|
  puts "name is now #{name}"
end
person.name = 'Joe'
# puts => "name is now Joe"

# Since listening is very common, you can easily shorthand this to:
wiretap = Motion.wiretap(person, :name) do |name|
  puts "name is now #{name}"
end

# bind the property of one object to the value of another
person_1 = Person.new
person_2 = Person.new
wiretap = Motion.wiretap(person_1, :name)
wiretap.bind_to(person_2, :name)  # creates a new Wiretap object for person_2; changes to person_2.name will affect person_1
person_2.name = 'Bob'
person_1.name # => "Bob"

# cancel a wiretap
wiretap.cancel!
person_2.name = 'Jane'
person_1.name
# => "BOB"

# bind the property of one object to the value of another, but change it using `map`
wiretap = Motion.wiretap(person_1, :name).bind_to(Motion.wiretap(person_2, :name).map { |value| value.upcase })
person_2.name = 'Bob'
person_1.name # => "BOB"
```

### Working with arrays

```ruby
# combine the values `name` and `email`
person = Person.new
taps = Motion.wiretap([
  Motion.wiretap(person, :name),
  Motion.wiretap(person, :email),
]).combine do |name, email|
  puts "#{name} <#{email}>"
end

person.name = 'Kazuo'
# puts => "Kazuo <>"
person.email = 'kaz@example.com'
# puts => "Kazuo <kaz@example.com>"

# reduce/inject
person_1 = Person.new
person_2 = Person.new
taps = Motion.wiretap([
  Motion.wiretap(person_1, :name),
  Motion.wiretap(person_2, :name),
]).reduce do |memo, name|
  memo ||= []
  memo + [name]
end
wiretap.listen do |names|
  puts names.inspect
end
person_1.name = 'Mr. White'
person_1.name = 'Mr. Blue'
# => ["Mr. White", "Mr. Blue"]

# you can provide an initial 'memo' (default: nil)
Motion.wiretap([
  Motion.wiretap(person_1, :name),
  Motion.wiretap(person_2, :name),
]).reduce([]) do |memo, name|
  memo + [name]  # you should not change memo in place, the same one will be used on every change event
end
```

### Monitoring jobs

```ruby
# Monitor for background job completion:
Motion.wiretap(-> do
  this_will_take_forever!
end).and_then do
  puts "done!"
end.start

# Same, but specifying the thread to run on. The completion block will be called
# on this thread, too. The queue conveniently accepts a completion handler
# (delegates to the `Wiretap#and_then` method).
Motion.wiretap(-> do
  this_will_take_forever!
end).queue(Dispatch::Queue.concurrent).and_then do
  puts "done!"
end.start

# Send a stream of values from a block. A lambda is passed in that will forward
# change events to the `listen` block
Motion.wiretap(-> (on_change) do
  5.times do |count|
    on_change.call count
  end
end).listen do |index|
  puts "...#{index}"
end.and_then do
  puts "done!"
end.start
# => puts "...0", "...1", "...2", "...3", "...4", "done!"
```

### Notifications

```ruby
notification = Motion.wiretap('NotificationName') do
  puts 'notification received!'
end
# the notification observer will be removed when the Wiretap is dealloc'd
```

### Gestures

```ruby

```