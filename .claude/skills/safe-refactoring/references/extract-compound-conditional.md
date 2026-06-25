# Extract Compound Conditional

## When it applies
A conditional's truth depends on two-or-more sub-conditions joined by boolean
logic: `if foo && bar` / `if foo || bar`. Extracting it into a named method
almost always improves readability — it names the *higher-level concept* the
combination represents.

## Before / after
```ruby
# Before — reader has to compute the meaning
if user_created_account_today? && user_has_unconfirmed_email?
  send_welcome_nudge(user)
end

# After — the concept has a name
if user.recently_registered_with_unconfirmed_email?
  send_welcome_nudge(user)
end

def recently_registered_with_unconfirmed_email?
  created_account_today? && has_unconfirmed_email?
end
```

## Why it helps
- The call site reads as intent, not mechanics.
- The concept becomes testable and reusable on its own.
- The name documents *why* these conditions matter together.

## Safe step sequence
Pure refactor, no behavior change:
1. Extract the boolean expression into a well-named query method (a question —
   ends in `?` in Ruby).
2. Replace the inline expression with the call.
3. Run tests green.

## When NOT to
- The condition is already a single, clear concept used once and trivially.
- Naming it would just restate the code (`foo_and_bar?`) without adding meaning —
  find the real concept or leave it.
