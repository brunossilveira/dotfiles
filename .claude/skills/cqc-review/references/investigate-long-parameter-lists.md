# Investigate long parameter lists

## Why it matters
A long parameter list (here: **more than three** parameters) isn't automatically
wrong, but it frequently hides a design problem worth questioning.

## Detect
Long parameter lists are often line-wrapped, so some manual searching is needed.
A naive regex that catches single-line Ruby method definitions with 4+ params:
```sh
rg -n --no-heading 'def \w+[!?]?\(([^,)]+,){3,}' {path}
```
(The original challenge suggests the cruder `(.*,.*,.*,.*)` for method *calls*.)
Many hits will be calls into library/framework code — focus on your own code.

## Improve — questions to ask each long list
- **Should some data be instance data instead?** A tell: other methods on the
  object need the same parameter.
- **Do several params travel together?** That's a likely **Data Clump** — extract
  a value object to hold them.
- **Any boolean params?** Probably **control coupling**; you'd do well to remove
  it (often by splitting the method).
- **Can any param be removed outright?** It's surprisingly easy to keep passing
  something a method no longer uses.

These questions are worth asking of *any* parameter list, even short ones.
