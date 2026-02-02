# Mutation Operators

LeanMutator includes a comprehensive set of mutation operators designed for Lean 4 code.

## Boolean Operators

### `boolean-flip`

Flips boolean literals.

| Original | Mutated |
|----------|---------|
| `true` | `false` |
| `false` | `true` |

**Example:**
```lean
-- Original
def alwaysTrue : Bool := true

-- Mutated
def alwaysTrue : Bool := false
```

### `boolean-and-or`

Swaps logical operators.

| Original | Mutated |
|----------|---------|
| `&&` | `\|\|` |
| `\|\|` | `&&` |
| `∧` | `∨` |
| `∨` | `∧` |

**Example:**
```lean
-- Original
def both (a b : Bool) : Bool := a && b

-- Mutated
def both (a b : Bool) : Bool := a || b
```

### `boolean-negation`

Removes negation operators.

| Original | Mutated |
|----------|---------|
| `¬p` | `p` |
| `!x` | `x` |

**Example:**
```lean
-- Original
def isNotEmpty (s : String) : Bool := !s.isEmpty

-- Mutated
def isNotEmpty (s : String) : Bool := s.isEmpty
```

## Arithmetic Operators

### `arithmetic-add-sub`

Swaps addition and subtraction.

| Original | Mutated |
|----------|---------|
| `a + b` | `a - b` |
| `a - b` | `a + b` |

### `arithmetic-mul-div`

Swaps multiplication and division.

| Original | Mutated |
|----------|---------|
| `a * b` | `a / b` |
| `a / b` | `a * b` |

### `arithmetic-swap`

Swaps all arithmetic operators.

| Original | Mutated |
|----------|---------|
| `+` | `-`, `*` |
| `-` | `+`, `/` |
| `*` | `/`, `+` |
| `/` | `*`, `-` |

### `numeric-boundary`

Applies boundary value mutations.

| Original | Mutated |
|----------|---------|
| `n` | `n + 1` |
| `n` | `n - 1` |
| `n` (n ≠ 0) | `0` |

**Example:**
```lean
-- Original
def bufferSize : Nat := 1024

-- Mutated (three variants)
def bufferSize : Nat := 1025
def bufferSize : Nat := 1023
def bufferSize : Nat := 0
```

## Comparison Operators

### `comparison-equality`

Swaps equality operators.

| Original | Mutated |
|----------|---------|
| `=` | `≠` |
| `≠` | `=` |
| `==` | `!=` |
| `!=` | `==` |

### `comparison-relational`

Mutates relational operators.

| Original | Mutated |
|----------|---------|
| `<` | `≤`, `>` |
| `≤` | `<`, `≥` |
| `>` | `≥`, `<` |
| `≥` | `>`, `≤` |

### `comparison-boundary`

Converts relational operators to equality.

| Original | Mutated |
|----------|---------|
| `<` | `=` |
| `>` | `=` |
| `≤` | `=` |
| `≥` | `=` |

## Literal Operators

### `string-literal`

Mutates string literals.

| Original | Mutated |
|----------|---------|
| `"hello"` | `""` |
| `"hello"` | `"MUTATED"` |
| `""` | `"non-empty"` |

### `char-literal`

Mutates character literals.

| Original | Mutated |
|----------|---------|
| `'x'` | `' '` |
| `'x'` | `'a'` |
| `'a'` | `'0'` |

## Selecting Operators

Use the `--operators` flag to select specific operators:

```bash
# Use only boolean operators
lake exe leanmutator mutate src/ --operators "boolean-flip,boolean-and-or"

# Use only arithmetic operators
lake exe leanmutator mutate src/ --operators "arithmetic-add-sub,arithmetic-mul-div"
```

Or configure in `.leanmutator.toml`:

```toml
operators = ["boolean-flip", "comparison-equality"]
```

## Operator Statistics

After a mutation run, the JSON report includes per-operator statistics:

```json
{
  "operatorStats": {
    "boolean-flip": { "total": 5, "killed": 4, "survived": 1 },
    "arithmetic-add-sub": { "total": 3, "killed": 3, "survived": 0 }
  }
}
```

This helps identify which types of mutations your tests are weak against.
