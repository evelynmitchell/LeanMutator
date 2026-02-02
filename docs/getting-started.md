# Getting Started with LeanMutator

This guide will help you set up LeanMutator and run your first mutation tests.

## Prerequisites

- **Lean 4**: LeanMutator requires Lean 4.0.0 or later
- **Lake**: The Lean build tool (included with Lean 4)
- **Git**: For cloning and version control

## Installation

### Option 1: Add as Dependency

Add LeanMutator to your project's `lakefile.toml`:

```toml
[[require]]
name = "LeanMutator"
git = "https://github.com/leanprover/leanmutator"
rev = "main"
```

Then update and build:

```bash
lake update
lake build
```

### Option 2: Build from Source

Clone and build LeanMutator directly:

```bash
git clone https://github.com/leanprover/leanmutator
cd leanmutator
lake build
```

## Running Your First Mutation Test

1. **Create a simple Lean file** (`Example.lean`):

```lean
def isPositive (n : Int) : Bool := n > 0

#guard isPositive 5 = true
```

2. **Run mutation testing**:

```bash
lake exe leanmutator mutate Example.lean
```

3. **Review results**:

```
Mutation Testing Results
══════════════════════════════
Score: 50%
──────────────────────────────
Total Mutations: 2
  ✓ Killed:   1
  ✗ Survived: 1
```

The surviving mutation indicates a weak test! The mutation `n > 0` → `n >= 0` wasn't caught because we don't test the boundary case `n = 0`.

4. **Improve your tests**:

```lean
def isPositive (n : Int) : Bool := n > 0

#guard isPositive 5 = true
#guard isPositive 0 = false  -- Now catches the boundary mutation!
#guard isPositive (-1) = false
```

5. **Re-run** to see improved score:

```
Score: 100%
```

## Understanding the Output

- **Killed**: Mutations that caused tests to fail (good!)
- **Survived**: Mutations that tests didn't catch (indicates weak tests)
- **Timeout**: Mutations that exceeded time limit
- **Errors**: Mutations that caused build errors

## Next Steps

- Read about [Mutation Operators](operators.md)
- Learn [Configuration](configuration.md) options
- Set up [CI Integration](ci-integration.md)
- Try the [First Mutation Tutorial](tutorials/first-mutation.md)
