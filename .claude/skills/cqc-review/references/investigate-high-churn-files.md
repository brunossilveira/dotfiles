# Investigate high-churn files

## Why it matters
Churn = the number of times a file has changed. High-churn files aren't
necessarily bad, but they often flag a refactoring opportunity. A file that
changes constantly may be unclear (and therefore buggy), or doing too many
things.

## Detect
Count commits per file with Git:
```sh
git log --all -M -C --name-only --format='format:' "$@" \
  | sort \
  | grep -v '^$' \
  | uniq -c \
  | sort -n \
  | awk 'BEGIN {print "count\tfile"} {print $1 "\t" $2}'
```
Worth saving as an executable script (e.g. `git-churn`) so you can pass
parameters. For example, the top files changed most in the last 3 months:
```sh
git-churn --since='3 months ago' <core_of_the_app> | tail -10
```

## Improve
Look at the highest-churn files and ask:
- Does anything stand out as a reason it changes so often?
- Is it unclear, doing too much, or structurally unstable?
- Is it worth trying to make it more stable (split responsibilities, clarify the
  abstraction, add a seam)?

Strongest signal: a file that is **both high-churn and large** — cross-reference
with the large-class detector.
