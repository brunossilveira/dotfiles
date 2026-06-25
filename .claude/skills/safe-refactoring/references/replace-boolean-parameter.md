# Replace Boolean Parameter

## When it applies
A boolean argument **selects behavior** rather than carrying data — *control
coupling*. The call site reads like a riddle: `render(true)`, `save(false)` —
you can't tell what `true` means without opening the method.

## Before / after
```ruby
# Before — flag controls which path runs
def export(data, as_csv)
  as_csv ? to_csv(data) : to_json(data)
end
export(data, true)   # ??? what is true

# After A — two intention-revealing methods
def export_csv(data) = to_csv(data)
def export_json(data) = to_json(data)
export_csv(data)

# After B — explicit, self-documenting argument (when a flag must stay)
def export(data, format:)   # format: :csv | :json
  format == :csv ? to_csv(data) : to_json(data)
end
export(data, format: :csv)
```
Prefer **A** (split methods) when the two paths share little; **B** (an explicit
keyword/enum) when they share a lot of logic.

## Safe step sequence
1. Find every call site (grep for the method).
2. Add the new method(s) / keyword form *alongside* the old signature.
3. Migrate call sites one at a time, tests green after each.
4. Remove the old boolean parameter once unused.

## When NOT to
- The boolean is genuine **data**, not a control flag — e.g. `User.new(active: true)`
  where `active` is a real attribute. Named keyword booleans for data are fine.
