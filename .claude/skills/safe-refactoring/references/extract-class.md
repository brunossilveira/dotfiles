# Extract Class

## When it applies
A class has grown large and a subset of its methods/fields **clump together** —
they share parameters, touch the same instance data, or share a word in their
names. That clump is a second responsibility hiding inside the class.

## Before / after
```ruby
# Before — Order also knows how to format an address
class Order
  def shipping_label
    "#{@street}\n#{@city}, #{@zip}"
  end
  def same_region?(other) = @zip[0..1] == other_zip[0..1]
  # ...order stuff...
end

# After — address concerns live in their own object
class Address
  def initialize(street, city, zip) = (@street, @city, @zip = street, city, zip)
  def label = "#{@street}\n#{@city}, #{@zip}"
  def same_region?(other) = @zip[0..1] == other.zip[0..1]
  attr_reader :zip
end

class Order
  def shipping_label = @address.label   # delegates
end
```

## Safe step sequence
1. **Name the clump.** Identify the methods + fields that move together. If you
   can't name the new concept, you haven't found a real clump — stop.
2. **Create the empty new class.**
3. **Move one field/method at a time.** After each move, have the old class
   *delegate* to the new one and run tests. Stay green at every step.
4. **Decide the relationship.** Either the old class holds the new one and
   delegates, or callers talk to the new class directly. Migrate callers
   incrementally if the latter.
5. **Remove the now-dead delegation** once nothing uses it.

## When NOT to
- No cohesive clump — extraction would just scatter related logic.
- Heavy coupling resists a clean cut and the move can't be finished safely.

In either case, fall back to a small in-place improvement (rename, make a method
private, slim one long method, delete dead code) rather than forcing the split.
