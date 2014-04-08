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
notifications or control events.  When you compose them in this way you only
need to retain the "bottom most" wiretap.  Examples follow.


### Let's start with something practical!

In these examples I will use all three ways of creating a Wiretap
(`MW(), Motion.wiretap(), object.wiretap`).

```ruby
# assign the label to the text view; changes to the text view will be reflected
# on the label.
@wiretap = MW(@label, :text).bind_to(MW(@text_view, :text))

# assign the attributedText of the label to the text view, doing some
# highlighting in-between.
@wiretap = @label.wiretap(:attributedText).bind_to(@text_view.wiretap(:text).map do |text|
  NSAttributedString.alloc.initWithString(text, attributes: { NSForegroundColorAttributeName => UIColor.blueColor })
end)

# This code will set the 'enabled' property depending on whether the username
# and password are not empty.
@wiretap = Motion.wiretap(@login_button, :enabled).bind_to(
  Motion.wiretap([
    Motion.wiretap(@username_field, :text),
    Motion.wiretap(@password_field, :text),
  ]).combine do |username, password|
    # use motion-support to get the 'present?' method
    username.present? && password.present?
  end
  )
```

See how in the example above I only retain the "final" signal (the return value
from `#combine` is what gets retained by `@wiretap`). That's what I mean by the
"bottom most" wiretap.  Don't worry, the intermediate wiretaps get retained.

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
@wiretap = Motion.wiretap(person, :name)
# react to change events
@wiretap.listen do |name|
  puts "name is now #{name}"
end
person.name = 'Joe'
# puts => "name is now Joe"

# Since listening is very common, you can easily shorthand this to:
@wiretap = Motion.wiretap(person, :name) do |name|
  puts "name is now #{name}"
end

# bind the property of one object to the value of another
person_1 = Person.new
person_2 = Person.new
@wiretap = Motion.wiretap(person_1, :name)
@wiretap.bind_to(person_2, :name)  # creates a new Wiretap object for person_2; changes to person_2.name will affect person_1
person_2.name = 'Bob'
person_1.name # => "Bob"

# cancel a wiretap
@wiretap.cancel!
person_2.name = 'Jane'
person_1.name
# => "BOB"

# bind the property of one object to the value of another, but change it using `map`
@wiretap = Motion.wiretap(person_1, :name).bind_to(Motion.wiretap(person_2, :name).map { |value| value.upcase })
person_2.name = 'Bob'
person_1.name # => "BOB"
```

### Working with arrays

```ruby
# combine the values `name` and `email`, which means they'll be sent together
# when either one changes
person = Person.new
@info = nil
@taps = Motion.wiretap([
  Motion.wiretap(person, :name),
  Motion.wiretap(person, :email),
]).combine do |name, email|
  @info = "#{name} <#{email}>"
end

person.name = 'Kazuo'
# @info => "Kazuo <>"
person.email = 'kaz@example.com'
# @info => "Kazuo <kaz@example.com>"

# With reduce you get a memo and a value, and you should return a new value. Be
# careful about mutable structures: the initial memo is retained, not copied.
person_1 = Person.new
person_2 = Person.new
@names = []
@taps = Motion.wiretap([
  Motion.wiretap(person_1, :name),
  Motion.wiretap(person_2, :name),
]).reduce([]) do |memo, name|
  memo + [name]
end.listen do |names|
  @names = names.inspect
end
person_1.name = 'Mr. White'
# @names => ["Mr. White", nil]
person_2.name = 'Mr. Blue'
# @names => ["Mr. White", "Mr. Blue"]
```

### Monitoring jobs

There is a "short form" and "long form" to these wiretaps.  The "short form" is
something like `Motion.wiretap(proc) do (block) end`.  The `proc` will be
executed, and when it's done, the `block` will execute.

The "long form" is different only in that the block is passed to the `and_then`
method, not the initializer: `Motion.wiretap(proc).and_then do ... end`.  In
this form, you must call `start` on the wiretap:

```ruby
# Monitor for background job completion, short form:
@wiretap = Motion.wiretap(-> do
  this_will_take_forever!
end) do
  puts "done!"
end

# Monitor for background job completion, long form:
@wiretap = Motion.wiretap(-> do
  this_will_take_forever!
end).and_then do
  puts "done!"
end.start  # you must call 'start' explicitly

# Same again, but specifying the thread to run on. The completion block will be
# called on this thread, too. The queue conveniently accepts a completion
# handler (delegates to the `Wiretap#and_then` method).
@wiretap = Motion.wiretap(-> do
  this_will_take_forever!
end).queue(Dispatch::Queue.concurrent).and_then do
  puts "done!"
end
@wiretap.start

# Send a stream of values from a block. A lambda is passed in that will forward
# change events to the `listen` block
@wiretap = Motion.wiretap(-> (on_change) do
  5.times do |count|
    on_change.call count
    sleep(1)
  end
end).listen do |index|
  puts "...#{index}"
end.and_then do
  puts "done!"
end.start
# => puts "...0", "...1", "...2", "...3", "...4", "done!"
```

### Gestures

Possible gestures:

    :tap, :pinch, :rotate, :swipe, :pan, :press

Options:

    :taps (:tap, :press)
    :fingers (:tap, :swipe, :pan, :press)
    :direction (:direction)
    :min_fingers (:pan)
    :max_fingers (:pan)
    :duration (:press)

```ruby
@wiretap = Motion.wiretap(view).on(:tap) do |gesture|
  point = gesture.locationInView(view)
  puts "you tapped #{point.x}, #{point.y}"
end
```

### Control events

Possible events:

    :touch, :touch_up, :touch_down, :touch_start, :touch_stop, :change, :begin,
    :end, :touch_down_repeat, :touch_drag_inside, :touch_drag_outside,
    :touch_drag_enter, :touch_drag_exit, :touch_up_inside, :touch_up_outside,
    :touch_cancel, :value_changed, :editing_did_begin, :editing_changed,
    :editing_did_change, :editing_did_end, :editing_did_end_on_exit
    :all_touch, :all_editing, :application, :system, :all

```ruby
@wiretap = Motion.wiretap(control).on(:touch) do |event|
end
```

### Notifications

```ruby
@wiretap = Motion.wiretap('NotificationName') do |object, user_info|
  puts 'notification received!'
end

NSNotificationCenter.defaultCenter.postNotificationName('NotificationName', object: nil, userInfo: info)
```
