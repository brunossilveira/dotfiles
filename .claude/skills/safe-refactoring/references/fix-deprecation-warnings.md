# Fix a deprecation / warning

## When it applies
Code prints a warning on boot, test run, dependency install, or deploy.
Deprecations especially are time bombs — they become hard breakages on the next
upgrade, usually at an inconvenient moment. They're also a *broken window*: a
visible signal the codebase tolerates mess.

## Safe step sequence
1. **Capture the exact warning and its source.** Get the message and the
   `file:line` — it points either into your code or into a gem. Re-run the step
   with the warning visible:
   ```sh
   bundle exec rspec 2>&1 | grep -i 'warning\|deprecat'
   ```
2. **Read the message — it usually names the replacement.** Good deprecation
   warnings tell you the new API to use.
3. **Apply the fix:**
   - *Your code* → switch to the replacement API.
   - *A gem you control the usage of* → check the gem's changelog/upgrade guide
     for the migration.
   - *A transitive dependency you don't control* → upgrade or pin the gem; if
     there's no fix yet, document it rather than silencing it.
4. **Re-run** the same step and confirm the warning is gone.

## Safety
A deprecation fix is a **behavior change** (you're swapping APIs) — keep tests
green and do it in its own commit, isolated from refactors.

## When NOT to
- Don't silence warnings with suppression flags / `$VERBOSE = nil` to make them
  "go away." That boards up the broken window instead of fixing it and hides the
  next real one.
