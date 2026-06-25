# Investigate slowest test

## Why it matters
Slow tests are a constant drag on forward progress. Keeping one is only worth it
when its value outweighs that ongoing cost.

## Detect
Find your ~10 slowest tests. With Ruby/RSpec, just add `--profile`:
```sh
bundle exec rspec --profile 10
```
Other runners usually have an equivalent flag a quick search away.

## Improve
Give each slow test a once-over and ask:
- **Duplicate?** It's easy to accidentally write the same test twice — diffs in a
  PR won't reveal it, so duplication creeps in over time.
- **Faster variant?** Can a broad integration spec become a view/unit spec? Can
  you stub expensive calls, do less setup, or hit less of the stack and still be
  confident?
- **Still pulling its weight?** Be pragmatic. If a very slow test verifies
  something non-critical, consider deleting it.

## Cost note
This detector requires actually running the suite, so it's expensive — gate it
behind an explicit opt-in rather than running it on every sweep.
