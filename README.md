# Comment Revision Checker

This is a temporary repository, to test a script, that checks if the developer has changed functions and not updated their comments.

First attempt only indactes function comments and not class comments.

Used [Analyzer](https://pub.dev/packages/analyzer) to parse the changed files.

## Getting Started

1. Make a change to a function (model_test.dart, was created for this purpose, but any function that has a /// comment above it should work);
2. Run this command (be sure to be at the root of the project): 

```
dart comment_checker.dart
```

Should print out the functions files and their functions (name and line) that require comment revision.