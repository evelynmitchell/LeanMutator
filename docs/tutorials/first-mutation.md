# Tutorial: Your First Mutation Test

Learn mutation testing by testing a simple `isEven` function.

## Overview

In this tutorial, you'll:
1. Create a simple Lean project
2. Write code with tests
3. Run mutation testing
4. Identify weak tests
5. Improve your test suite

## Step 1: Create a Test Project

```bash
lake new MutationDemo lib
cd MutationDemo
```

## Step 2: Write Code with a Simple Test

Edit `MutationDemo/Basic.lean`:

```lean
def isEven (n : Nat) : Bool := n % 2 == 0

-- A simple test
#guard isEven 4 = true
```

## Step 3: Add LeanMutator

Edit `lakefile.toml` to add LeanMutator:

```toml
[[require]]
name = "LeanMutator"
git = "https://github.com/leanprover/leanmutator"
rev = "main"
```

Build:
```bash
lake update
lake build
```

## Step 4: Run LeanMutator

```bash
lake exe leanmutator mutate MutationDemo/Basic.lean
```

Output:
```
Mutating: MutationDemo/Basic.lean
Found 3 mutation points in MutationDemo/Basic.lean

Mutation Testing Results
══════════════════════════════
Score: 33%
──────────────────────────────
Total Mutations: 3
  ✓ Killed:   1
  ✗ Survived: 2
  ⏱ Timeout:  0
  ⚠ Errors:   0
──────────────────────────────
Total Time: 45ms

Surviving Mutations (weak tests):
  • MutationDemo/Basic.lean:1 - comparison-equality: == → !=
  • MutationDemo/Basic.lean:1 - numeric-boundary: 2 → 3
```

## Step 5: Interpret Results

The mutation score of 33% is low! Let's understand what happened:

### Mutation 1: `n % 2 == 0` → `n % 2 != 0` (SURVIVED)

This mutation changed equality to inequality. Our test `isEven 4 = true` didn't catch this because we don't test any odd numbers.

### Mutation 2: `n % 2 == 0` → `n % 3 == 0` (SURVIVED)

This mutation changed the divisor. Our test only checks 4, which happens to not be divisible by 3, so this mutation survives.

### Mutation 3: `== 0` → `== 1` (KILLED)

This was caught because `4 % 2 = 0`, not 1.

## Step 6: Improve Tests

Add more comprehensive tests:

```lean
def isEven (n : Nat) : Bool := n % 2 == 0

-- Comprehensive tests
#guard isEven 0 = true    -- Edge case: zero
#guard isEven 1 = false   -- Odd number
#guard isEven 2 = true    -- Even number
#guard isEven 3 = false   -- Odd number
#guard isEven 4 = true    -- Even number
#guard isEven 100 = true  -- Larger even
#guard isEven 101 = false -- Larger odd
```

## Step 7: Re-run Mutation Testing

```bash
lake exe leanmutator mutate MutationDemo/Basic.lean
```

Output:
```
Mutation Testing Results
══════════════════════════════
Score: 100%
──────────────────────────────
Total Mutations: 3
  ✓ Killed:   3
  ✗ Survived: 0
```

All mutations are now killed.

## What We Learned

1. **One test isn't enough**: Testing only positive cases leaves bugs undetected
2. **Boundary values matter**: Testing 0, 1, and the boundary between even/odd
3. **Mutation testing reveals gaps**: Traditional coverage might show 100%, but mutation testing exposes weak tests
4. **Improving tests improves confidence**: High mutation score means your tests catch real bugs

## Next Steps

- Try the [Custom Operators Tutorial](custom-operators.md)
- Learn about [Interpreting Results](interpreting-results.md)
- Set up [CI Integration](../ci-integration.md)

## Common Patterns

### Testing Boolean Functions

Always test both `true` and `false` outcomes:

```lean
#guard myPredicate positiveCase = true
#guard myPredicate negativeCase = false
```

### Testing Arithmetic

Test boundaries and special cases:

```lean
#guard add 0 0 = 0      -- Zero case
#guard add 1 0 = 1      -- Identity
#guard add 0 1 = 1      -- Commutativity
#guard add 5 3 = 8      -- Normal case
```

### Testing Comparisons

Test all sides of the comparison:

```lean
#guard isLessThan 1 2 = true   -- Less
#guard isLessThan 2 2 = false  -- Equal
#guard isLessThan 3 2 = false  -- Greater
```
