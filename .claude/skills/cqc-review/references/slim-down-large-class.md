# Slim down a large class

## Why it matters
A few classes always drift toward large and unwieldy. Length itself isn't a bug,
but a long class is a strong signal that it's doing too many things and is ripe
for extracting a smaller, focused object.

## Detect
Find the longest source files (a proxy for the largest classes):
```sh
find {path} -name '*.rb' | xargs wc -l | sort -rn | head
```
Pick one that looks like a good candidate and open it.

## Improve — extract a clump
Scan the class for groups of methods that "clump together." Signals that methods
belong in the same extracted object:
- Several methods that take the **same parameter**.
- Several methods that access the **same instance data**.
- Several methods that share a **word in their name**.

When several methods share these traits, try extracting them into a new class and
see if it's a worthwhile improvement.

## Caveat & fallback
A big class often has coupling that resists extraction in one sitting — and
sometimes there's no clean clump to pull. That's fine. Fall back to improving
*something* small:
- Delete a stray comment.
- Improve a name.
- Make a method private if it's only called internally.
- Fix ugly formatting (trailing whitespace, inconsistent newlines).
- Slim down one long method.
- Delete unused code.

"No good extraction found" is a valid outcome. The goal is one small step, not a
forced rewrite.
