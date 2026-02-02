# Tutorial: Writing Custom Operators

Learn how to extend LeanMutator with your own mutation operators.

## Overview

LeanMutator's mutation operators are defined using a simple structure. You can create custom operators to:

- Handle domain-specific patterns
- Add Lean-specific mutations
- Target particular code patterns in your codebase

## Anatomy of a Mutation Operator

Every mutation operator has three components:

```lean
structure MutationOperator where
  /-- Unique name identifying this operator -/
  name : String
  /-- Description of what this operator does -/
  description : String
  /-- Check if this operator applies to the given syntax -/
  canMutate : Syntax → Bool
  /-- Generate all possible mutations for the given syntax -/
  mutate : Syntax → Array (Syntax × String)
```

## Example: List Operation Mutator

Let's create an operator that mutates list operations.

### Step 1: Define Pattern Matching

```lean
import Lean
import LeanMutator.Mutator.Operators

namespace MyCustomOperators

open Lean
open LeanMutator.Mutator

/-- Check if syntax is a list head operation -/
def isListHead (stx : Syntax) : Bool :=
  match stx with
  | .node _ kind args =>
    args.any fun arg =>
      match arg with
      | .ident _ _ name _ => name.toString == "head" || name.toString == "head!"
      | _ => false
  | _ => false

/-- Check if syntax is a list tail operation -/
def isListTail (stx : Syntax) : Bool :=
  match stx with
  | .node _ kind args =>
    args.any fun arg =>
      match arg with
      | .ident _ _ name _ => name.toString == "tail" || name.toString == "tail!"
      | _ => false
  | _ => false
```

### Step 2: Implement Mutations

```lean
/-- Replace head with tail in syntax -/
partial def replaceHeadWithTail (stx : Syntax) : Syntax :=
  match stx with
  | .ident info rawVal name preresolved =>
    if name.toString == "head" then
      .ident info "tail".toSubstring `tail preresolved
    else if name.toString == "head!" then
      .ident info "tail!".toSubstring `tail! preresolved
    else
      stx
  | .node info kind args =>
    .node info kind (args.map replaceHeadWithTail)
  | _ => stx

/-- Replace tail with head in syntax -/
partial def replaceTailWithHead (stx : Syntax) : Syntax :=
  match stx with
  | .ident info rawVal name preresolved =>
    if name.toString == "tail" then
      .ident info "head".toSubstring `head preresolved
    else if name.toString == "tail!" then
      .ident info "head!".toSubstring `head! preresolved
    else
      stx
  | .node info kind args =>
    .node info kind (args.map replaceTailWithHead)
  | _ => stx
```

### Step 3: Create the Operator

```lean
/-- List head/tail swap operator -/
def listHeadTailOperator : MutationOperator := {
  name := "list-head-tail"
  description := "Swap list head and tail operations"
  canMutate := fun stx => isListHead stx || isListTail stx
  mutate := fun stx =>
    if isListHead stx then
      #[(replaceHeadWithTail stx, "head → tail")]
    else if isListTail stx then
      #[(replaceTailWithHead stx, "tail → head")]
    else
      #[]
}

def allOperators : Array MutationOperator := #[
  listHeadTailOperator
]

end MyCustomOperators
```

### Step 4: Register with LeanMutator

Create a file that registers your custom operators:

```lean
-- CustomOperators.lean
import LeanMutator
import MyCustomOperators

namespace MyProject

def customRegistry : LeanMutator.Mutator.OperatorRegistry :=
  LeanMutator.defaultRegistry
    |>.register MyCustomOperators.listHeadTailOperator

end MyProject
```

## More Examples

### Option Mutation

```lean
/-- Mutate Option operations: some ↔ none -/
def optionMutator : MutationOperator := {
  name := "option-some-none"
  description := "Swap Option.some with Option.none"
  canMutate := fun stx =>
    match stx with
    | .ident _ _ name _ => name.toString == "some" || name.toString == "none"
    | _ => false
  mutate := fun stx =>
    match stx with
    | .ident info _ name preresolved =>
      if name.toString == "some" then
        #[(.ident info "none".toSubstring `none preresolved, "some → none")]
      else if name.toString == "none" then
        -- Can't easily mutate none → some without value
        #[]
      else
        #[]
    | _ => #[]
}
```

### Array Index Mutation

```lean
/-- Mutate array indices: a[i] → a[i+1], a[i-1], a[0] -/
def arrayIndexMutator : MutationOperator := {
  name := "array-index"
  description := "Mutate array index access"
  canMutate := fun stx =>
    -- Match array indexing syntax
    match stx with
    | .node _ kind _ =>
      kind.toString.containsSubstr "getOp" ||
      kind.toString.containsSubstr "index"
    | _ => false
  mutate := fun stx =>
    -- Implementation would extract and mutate the index
    #[]  -- Simplified for example
}
```

## Testing Your Operator

Create a test file with patterns your operator should catch:

```lean
-- tests/TestCustomOps.lean

def getFirst (xs : List Nat) : Option Nat := xs.head?
def getRest (xs : List Nat) : List Nat := xs.tail

#guard getFirst [1, 2, 3] = some 1
#guard getRest [1, 2, 3] = [2, 3]
```

Run with your operator:

```bash
lake exe leanmutator mutate tests/TestCustomOps.lean --operators "list-head-tail"
```

## Best Practices

1. **Keep operators focused**: One operator per concept
2. **Handle edge cases**: Empty syntax, missing children
3. **Use descriptive names**: Clear operator and mutation names
4. **Document mutations**: Clear before/after descriptions
5. **Test thoroughly**: Ensure pattern matching is correct

## Advanced: Syntax Quotations

For complex patterns, use Lean's syntax quotations:

```lean
/-- Match if-then-else and swap branches -/
def ifSwapOperator : MutationOperator := {
  name := "if-swap"
  description := "Swap if-then-else branches"
  canMutate := fun stx =>
    match stx with
    | `(if $cond then $thenBranch else $elseBranch) => true
    | _ => false
  mutate := fun stx =>
    match stx with
    | `(if $cond then $thenBranch else $elseBranch) =>
      #[(`(if $cond then $elseBranch else $thenBranch), "swap then/else")]
    | _ => #[]
}
```

## Next Steps

- See the built-in operators in `LeanMutator/Mutator/` for more examples
- Read about [Interpreting Results](interpreting-results.md)
- Share your operators with the community!
