# LeanMutator

Mutation testing tool for Lean 4, implemented in pure Lean 4 using native metaprogramming.

[![Mutation Score](https://img.shields.io/badge/mutation%20score-80%25-brightgreen)](https://github.com/leanprover/leanmutator)
[![Lean 4](https://img.shields.io/badge/Lean-4-blue)](https://lean-lang.org/)

## What is Mutation Testing?

Mutation testing is a powerful technique to evaluate the quality of your test suite. It works by:

1. **Creating mutants**: Making small changes to your code (mutations)
2. **Running tests**: Executing your test suite against each mutant
3. **Scoring**: Calculating how many mutants were "killed" (detected by tests)

A high mutation score indicates your tests are effective at catching bugs.

## Quick Start

### Installation

Add LeanMutator to your `lakefile.toml`:

```toml
[[require]]
name = "LeanMutator"
git = "https://github.com/leanprover/leanmutator"
rev = "main"
```

Then run:

```bash
lake update
lake build
```

### Basic Usage

```bash
# Mutate a single file
lake exe leanmutator mutate MyFile.lean

# Mutate an entire directory
lake exe leanmutator mutate src/

# List available mutation operators
lake exe leanmutator list-operators

# Create a config file
lake exe leanmutator init
```

## Mutation Operators

LeanMutator includes operators for common Lean constructs:

| Operator | Description | Example |
|----------|-------------|---------|
| `boolean-flip` | Flip boolean literals | `true` → `false` |
| `boolean-and-or` | Swap logical operators | `&&` → `\|\|` |
| `boolean-negation` | Remove negation | `¬p` → `p` |
| `arithmetic-add-sub` | Swap +/- | `a + b` → `a - b` |
| `arithmetic-mul-div` | Swap */ | `a * b` → `a / b` |
| `numeric-boundary` | Boundary values | `n` → `n+1`, `n` → `0` |
| `comparison-equality` | Swap equality | `=` → `≠` |
| `comparison-relational` | Swap relations | `<` → `≤` |
| `string-literal` | Mutate strings | `"hello"` → `""` |

## CLI Reference

```
leanmutator mutate <file|directory>...
  -o, --operators <list>   Comma-separated operator names
  -e, --exclude <patterns> Glob patterns to skip
  -t, --timeout <ms>       Per-mutation timeout (default: 60000)
  -p, --parallel <n>       Worker count (default: 1)
  -f, --format <format>    Output: console|json|html
  -r, --report <path>      Output file for json/html
  -v, --verbose            Show detailed output
  --no-color               Disable colored output

leanmutator list-operators
  -v, --verbose            Show operator descriptions

leanmutator init
  Create default .leanmutator.toml
```

## Configuration

Create a `.leanmutator.toml` file:

```toml
# Operators to use (empty = all)
operators = []

# Patterns to exclude
exclude = ["tests/", ".lake/"]

# Timeout per mutation (ms)
timeout = 60000

# Parallel workers
parallel = 4

# Output format
output = "console"

# Minimum passing score
threshold = 80
```

## Example Output

```
Mutation Testing Results
══════════════════════════════
Score: 85%
──────────────────────────────
Total Mutations: 20
  ✓ Killed:   17
  ✗ Survived: 3
  ⏱ Timeout:  0
  ⚠ Errors:   0
──────────────────────────────
Total Time: 1234ms

Surviving Mutations (weak tests):
  • src/Math.lean:42 - arithmetic-add-sub: + → -
  • src/Logic.lean:18 - boolean-flip: true → false
  • src/Utils.lean:7 - comparison-equality: = → ≠
```

## CI Integration

### GitHub Actions

```yaml
name: Mutation Testing

on: [push, pull_request]

jobs:
  mutation-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Lean
        uses: leanprover/lean-action@v1

      - name: Build
        run: lake build

      - name: Run Mutation Tests
        run: |
          lake exe leanmutator mutate src/ \
            --format json \
            --report mutation-report.json

      - name: Upload Report
        uses: actions/upload-artifact@v4
        with:
          name: mutation-report
          path: mutation-report.json
```

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Reference](docs/cli-reference.md)
- [Mutation Operators](docs/operators.md)
- [Configuration](docs/configuration.md)
- [CI Integration](docs/ci-integration.md)

### Tutorials

- [Your First Mutation Test](docs/tutorials/first-mutation.md)
- [Writing Custom Operators](docs/tutorials/custom-operators.md)
- [Interpreting Results](docs/tutorials/interpreting-results.md)

## License

Apache 2.0
