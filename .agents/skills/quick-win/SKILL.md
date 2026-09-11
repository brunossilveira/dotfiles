---
name: quick-win
description: Make one tiny, behavior-preserving improvement to the code at hand — extract a condition, slim a class, fix a name, or shrink a long parameter list
---

The goal is to improve the code while preserving its existing behavior. Do not change what the code does; only improve how it is structured, named, or expressed.

Scan its code and the code it is calling with one goal in mind: make something tiny better. A few examples:

## 1 - Extract a compound condition into a method with a meaningful, semantic name

## 2 - Slim down a long class

Look for opportunities to extract a new object.

When I do this, I’m looking for groups of methods that “clump together” in a related way.

Here are a few attributes that might identify “clumps” that may make sense to extract together:

1. Several methods that take the same parameter.
2. Several methods that access the same instance data.
3. Several methods that include the same word in their name.

When you see several methods that possess some of the above attributes, try extracting them into a new class and see if it feels like a worthwhile improvement.

Since you’re working on a large class, you may find it has a lot of coupling that resists extraction.

Alternatively, you might not be able to find a good candidate for extraction.

In either case, here’s a fallback task: improve SOMETHING about the class, even if it’s tiny. Here are a few ideas:

* Delete a stray comment.
* Improve a name.
* Make something private if it’s only called internally.
* Improve the formatting/style of any ugly bits (got any trailing whitespace or inconsistent newlines?).
* Slim down a long method.
* Delete some unused code.

## 3 - Improve one name

It can be a class name, a method name, a variable name, a constant name, a file name, anything.

If you just thought of a name you know needs improving, do that one.

If you can’t find a name that could be improved, consider these questions:

* Do you ever refer to the same concept slightly differently in different spots?
* Have you noticed anywhere where a previous rename missed a few references?
* Pop open your schema. Are your database columns named consistently? (This is just a special case of the first one.)
* Is the name you’d use to describe a concept to a coworker the same as what’s in the code?
* Is the name your customers would use the same as what’s in the code?

## 4 - Find and nuke long parameter lists

Finding a long parameter list doesn’t necessarily mean there’s anything wrong, but it’s worth asking yourself a few questions about them:

1. Should any of the data that you’re passing in be instance data instead?

   A clear indication this is true is if other methods on this object also require the same parameter.

2. Do you frequently pass several of these parameters together?

   If so, it’s possible you have a Data Clump 1 and could benefit from extracting a value object to contain them.

3. Are any of these parameters booleans?

   If so, you probably have a case of control coupling 1, and would do well to remove it.

4. Can any of these parameters be removed outright?

   You’d be surprised how easy it is to continue passing something into a method that no longer requires it.
