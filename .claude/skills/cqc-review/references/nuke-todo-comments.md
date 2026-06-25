# Nuke TODO comments

## Why it matters
Code is a lousy place to track todos. A TODO living in code can't be prioritized
or scheduled, and tends to get forgotten.

## Detect
```sh
rg -n --no-heading '\b(TODO|FIXME|HACK|XXX)\b' {path}
```

## Improve
For each comment, do one of:
1. **Out of date?** Delete it.
2. **Still relevant?** Delete it and add it to your real work tracker (GitHub
   Issues, Linear, Trello, etc.).
3. **Unsure?** Do a little research and/or track down the author to get an answer,
   then do 1 or 2.

For extra points, submit a PR that deletes all TODO comments at once and links to
the newly-created issue for each — an easy review/approval.
