# Configuration

LeanMutator can be configured via command-line flags or a `.leanmutator.toml` configuration file.

## Configuration File

Create a `.leanmutator.toml` file in your project root:

```bash
lake exe leanmutator init
```

### Full Configuration Reference

```toml
# LeanMutator Configuration

# Mutation operators to use
# Empty array means use all operators
# Available: boolean-flip, boolean-and-or, boolean-negation,
#            arithmetic-add-sub, arithmetic-mul-div, arithmetic-swap,
#            numeric-boundary, comparison-equality, comparison-relational,
#            comparison-boundary, string-literal, char-literal
operators = []

# File patterns to exclude from mutation testing
# Supports glob patterns
exclude = [
  "tests/",
  "*Test.lean",
  "*Spec.lean",
  ".lake/",
  "lake-packages/"
]

# Timeout per mutation in milliseconds
# Mutations exceeding this time are marked as "timeout"
timeout = 60000

# Number of parallel workers
# Use 1 for sequential execution
# Use 0 or omit to auto-detect CPU count
parallel = 4

# Output format: "console", "json", "html"
output = "console"

# Path for report file (when using json or html output)
# If not set, output goes to stdout
# report = "mutation-report.html"

# Minimum mutation score threshold (0-100)
# Exit with error if score is below this value
threshold = 80

# Source directories to scan (when no files specified on command line)
# sources = ["src/", "lib/"]

# Test command to run for each mutation
# Default is "lake build" for compile-time checking
# test_command = "lake test"
```

## Configuration Precedence

Configuration is applied in this order (later overrides earlier):

1. Default values
2. `.leanmutator.toml` file
3. Command-line flags

Example:
```bash
# Config file sets parallel = 4, but CLI overrides to 8
lake exe leanmutator mutate src/ --parallel 8
```

## Common Configurations

### Development (Fast Feedback)

```toml
# Quick feedback during development
operators = ["boolean-flip", "comparison-equality"]
timeout = 10000
parallel = 8
output = "console"
threshold = 0  # Don't fail on low score
```

### CI Pipeline (Thorough)

```toml
# Thorough testing in CI
operators = []  # Use all operators
timeout = 120000
parallel = 4
output = "json"
report = "mutation-report.json"
threshold = 80
```

### Large Codebase

```toml
# Optimize for large projects
exclude = [
  "tests/",
  "examples/",
  "benchmarks/",
  ".lake/",
  "deprecated/"
]
timeout = 30000
parallel = 16
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `NO_COLOR` | Disable colored output | `NO_COLOR=1` |
| `LEANMUTATOR_CONFIG` | Custom config file path | `LEANMUTATOR_CONFIG=ci.toml` |

## Per-File Configuration

You can exclude specific functions from mutation using comments:

```lean
-- leanmutator: skip
def generatedCode : Nat := 42

-- Regular code will be mutated
def myFunction : Nat := 1 + 2
```

## Validation

LeanMutator validates your configuration on startup. Invalid configurations produce helpful error messages:

```
Error: Invalid operator name 'invalid-op' in configuration
Valid operators: boolean-flip, boolean-and-or, ...
```
