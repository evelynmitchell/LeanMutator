# CLI Reference

Complete reference for LeanMutator command-line interface.

## Commands

### `leanmutator mutate`

Run mutation testing on Lean files.

```bash
leanmutator mutate <file|directory>...
```

#### Arguments

- `<file|directory>...`: One or more files or directories to mutate

#### Flags

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--operators` | `-o` | String | (all) | Comma-separated list of operator names |
| `--exclude` | `-e` | String | | Comma-separated patterns to exclude |
| `--timeout` | `-t` | Nat | 60000 | Per-mutation timeout in milliseconds |
| `--parallel` | `-p` | Nat | 1 | Number of parallel workers |
| `--format` | `-f` | String | console | Output format: console, json, html |
| `--report` | `-r` | String | | Path for json/html report file |
| `--verbose` | `-v` | | | Show detailed output |
| `--no-color` | | | | Disable colored output |
| `--isolated` | | | | Test mutations in isolation (parse only) |

#### Examples

```bash
# Mutate a single file
lake exe leanmutator mutate src/Math.lean

# Mutate a directory
lake exe leanmutator mutate src/

# Use specific operators
lake exe leanmutator mutate src/ --operators "boolean-flip,arithmetic-add-sub"

# Exclude test files
lake exe leanmutator mutate . --exclude "tests/,*Test.lean"

# Generate HTML report
lake exe leanmutator mutate src/ --format html --report report.html

# Run with 4 parallel workers
lake exe leanmutator mutate src/ --parallel 4

# Verbose output
lake exe leanmutator mutate src/ -v
```

### `leanmutator list-operators`

List all available mutation operators.

```bash
leanmutator list-operators
```

#### Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--verbose` | `-v` | Show operator descriptions |

#### Example

```bash
lake exe leanmutator list-operators -v
```

Output:
```
Available Mutation Operators:
═══════════════════════════════

boolean-flip
  Flip boolean literals: true → false, false → true

boolean-and-or
  Swap boolean operators: && ↔ ||, ∧ ↔ ∨

arithmetic-add-sub
  Swap addition and subtraction: + ↔ -

...

Total: 11 operators
```

### `leanmutator init`

Create a default `.leanmutator.toml` configuration file.

```bash
leanmutator init
```

Creates a `.leanmutator.toml` file in the current directory with sensible defaults.

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (mutation score >= threshold) |
| 1 | Failure (mutation score < threshold or error) |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `NO_COLOR` | Disable colored output when set |

## Output Formats

### Console (default)

Human-readable output with colors and Unicode symbols.

### JSON

Machine-readable format for CI integration:

```json
{
  "version": "1.0",
  "generator": "LeanMutator",
  "stats": {
    "total": 20,
    "killed": 17,
    "survived": 3,
    "timedOut": 0,
    "errors": 0,
    "score": 85.0,
    "totalTime": 1234
  },
  "mutations": [...]
}
```

### HTML

Visual report with source highlighting and interactive mutation list.
