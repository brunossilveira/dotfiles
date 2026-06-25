# Speed up slow tests

## When it applies
A handful of tests dominate suite runtime (found via `rspec --profile` or the
equivalent). Slow tests are a constant drag — only worth keeping when their value
outweighs that cost.

## Strategies, in order of preference
1. **Delete duplicates and low-value tests.** The same behavior is often tested
   more than once (you can't spot it in a single PR diff). And a very slow test
   verifying something non-critical may not be worth keeping at all.
2. **Push down the test pyramid.** Replace a broad integration/system spec with a
   unit or view spec when it gives equal confidence. Testing a view conditional?
   A view spec beats a full-stack integration spec.
3. **Do less setup.** Build only what the test needs — avoid creating whole object
   graphs. In Rails/FactoryBot: prefer `build` / `build_stubbed` over `create`,
   and avoid `let!` callbacks that run unconditionally.
4. **Stub expensive collaborators.** Network calls, external services, slow I/O —
   stub them. But never stub the thing under test.
5. **Hit less of the stack.** Don't go through the DB or the full request cycle
   when a narrower test proves the same point.

## Safety
Deleting or weakening a test changes the *suite's* behavior — its coverage. Be
deliberate: confirm the behavior that matters is still covered somewhere, and note
in the commit why a test was removed or downgraded. Keep these changes separate
from production-code changes.

## When NOT to
- The test is slow because it genuinely exercises a critical, hard-to-unit-test
  path (a real integration guarantee). Slow-but-essential beats fast-but-blind.
