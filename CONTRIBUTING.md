# How to contribute

_(This file is heavily based on [factory\_girl\_rails](https://github.com/thoughtbot/factory_girl_rails/blob/master/CONTRIBUTING.md)’s Contribution Guide)_

We love pull requests. Here’s a quick guide:

* Fork the repository.
* Run `rake spec` (to make sure you start with a clean slate).
* Implement your feature or fix.
* Add examples that describe it (in the `spec` directory). Only refactoring and documentation changes require no new tests. If you are adding functionality or fixing a bug, we need examples!
* Make sure `rake spec` passes after your modifications.
* Commit (bonus points for doing it in a `feature-*` branch).
* Push to your fork and send your pull request!

If we have not replied to your pull request in three or four days, do not hesitate to post another comment in it — yes, we can be lazy sometimes.

## Syntax Guide

Do not hesitate to submit patches that fix syntax issues. Some may have slipped under our nose.

* Two spaces, no tabs (but you already knew that, right?).
* No trailing whitespace. Blank lines should not have any space. There are few things we **hate** more than trailing whitespace. Seriously.
* `MyClass.my_method(my_arg)` not `my_method( my_arg )` or `my_method my_arg`.
* `[:foo, :bar]` and not `[ :foo, :bar ]`, `{ :foo => :bar }` and not `{:foo => :bar}`
* `a = b` and not `a=b`.
* Follow the conventions you see used in the source already.
