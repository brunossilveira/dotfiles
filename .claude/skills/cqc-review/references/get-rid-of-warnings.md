# Get rid of a warning

## Why it matters
Your code probably prints at least one warning during boot, tests, dependency
install, or deploy. They're easy to learn to ignore — but:
- Many warnings (especially deprecations) turn into full-blown breakages later,
  usually at an inconvenient time.
- They're a **broken window**: a signal the codebase isn't getting fastidious
  care. Tolerated small messes quietly teach the team that messes are fine, which
  breeds more. (See the broken-window theory.)

## Detect
There's no single command — capture warnings from whichever steps the project
runs:
```sh
# boot
<app boot command>   2>&1 | grep -i 'warning\|deprecat'
# tests
bundle exec rspec    2>&1 | grep -i 'warning\|deprecat'
# install
bundle install       2>&1 | grep -i 'warning\|deprecat'
# deploy
<deploy command>     2>&1 | grep -i 'warning\|deprecat'
```

## Improve
Eliminate at least one warning. If boot, tests, install, and deploy are all
warning-free — great, nothing to do. Otherwise, close one broken window.

## Cost note
Requires actually running boot/tests/install/deploy, so it's heavier — gate
behind explicit opt-in.
