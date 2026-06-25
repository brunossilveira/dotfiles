# Introduce Parameter Object

## When it applies
Several parameters keep **travelling together** across method signatures — a
*data clump*. Same group passed to multiple methods, or a method taking 4+ args
that form a coherent concept (a date range, a coordinate, an address).

## Before / after
```ruby
# Before — start/end passed together everywhere
def overlaps?(start_date, end_date, other_start, other_end) = ...
def duration(start_date, end_date) = end_date - start_date

# After — the clump becomes a value object
DateRange = Data.define(:start, :finish) do
  def overlaps?(other) = start <= other.finish && other.start <= finish
  def duration = finish - start
end
```
Bonus: behavior that operated on the clump (`overlaps?`, `duration`) now has a
natural home *on* the object — the param object often grows into a real domain type.

## Safe step sequence
1. **Create the value object**, immutable where possible (Ruby: `Data.define`, or
   `Struct`). No behavior yet — just the fields.
2. **Introduce it alongside** the existing params (add a new method/overload that
   takes the object, or have the object expose the individual values).
3. **Migrate callers incrementally**, running tests after each.
4. **Remove the old individual params** once no caller uses them.
5. **Pull related behavior onto the object** as a follow-up (separate commit).

## When NOT to
- The params don't actually form a concept — grouping them invents a fake
  abstraction that obscures more than it clarifies.
- They only co-occur in one place and aren't a recurring clump.
