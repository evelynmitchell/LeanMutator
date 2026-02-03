# Mutation Testing Status

Last updated: 2026-02-03 04:10:00 UTC

## Summary

| Metric | Value |
|--------|-------|
| Score | **94.81%** |
| Total Mutations | 154 |
| Killed | 146 |
| Survived | 8 |
| Timed Out | 0 |
| Errors | 0 |
| **Duration** | **2m 19s** |

## Test Configuration

- **Target**: `testdata/TestLib.lean`
- **Mode**: Build (full compilation)
- **Generator**: LeanMutator
- **Started**: 2026-02-03 04:07:00 UTC
- **Finished**: 2026-02-03 04:09:19 UTC

## Surviving Mutations

| Line | Operator | Original | Mutated |
|------|----------|----------|---------|
| 14 | comparison-relational | `>` | `>=` |
| 15 | comparison-relational | `<` | `<=` |
| 17 | comparison-relational | `<` | `<=` |
| 18 | comparison-relational | `>` | `>=` |
| 41 | numeric-boundary | `1` | `2` |
| 41 | numeric-boundary | `1` | `2` |
| 44 | comparison-relational | `<` | `<=` |
| 60 | arithmetic-add-sub | `-` | `+` |

## Notes

- Tests use `#guard` compile-time assertions
- Surviving mutations are boundary cases (`<` vs `<=`, `>` vs `>=`) where test inputs don't distinguish between the two
- Weekly automated runs are configured via GitHub Actions
