# Remove Dead Parameter

## When it applies
A method still accepts a parameter it no longer uses. It's surprisingly easy to
keep passing something into a method that stopped needing it — every caller pays
the noise cost for nothing.

## Safe step sequence
1. **Confirm it's truly unused.** Search the method body *and* watch for indirect
   uses:
   - reflection / metaprogramming (`send`, `method_missing`, `**kwargs` pass-through)
   - the param being forwarded to `super`
   - overrides/implementations in subclasses or a shared interface
2. **Check the contract.** Is the method public API, a framework callback, or
   overridden elsewhere? Removing an arg there breaks callers/contracts — may not
   be worth it, or needs a deprecation cycle.
3. **Remove from the signature**, update every call site, run tests green.

## When NOT to / caution
- **Public API or library boundary** — removal is a breaking change; deprecate
  first or leave it.
- **Overridden methods / duck-typed interfaces** — siblings may still need the
  param to keep a uniform signature.
- **Framework-called methods** (callbacks, hooks) where the framework passes the
  arg positionally.

Dead-param removal *is* a behavior-adjacent change at boundaries — keep it in its
own commit and verify callers compile/run.
