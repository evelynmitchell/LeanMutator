# Mutation Testing Status

Last updated: 2026-02-03 03:39:00 UTC

## Summary

| Metric | Value |
|--------|-------|
| Score | 0.00% |
| Total Mutations | 59 |
| Killed | 0 |
| Survived | 59 |
| Timed Out | 0 |
| Errors | 0 |
| **Duration** | **35s** |

## Test Configuration

- **Target**: `testdata/tests/Sample.lean`
- **Mode**: Isolated (parse-only)
- **Generator**: LeanMutator
- **Started**: 2026-02-03 03:38:25 UTC
- **Finished**: 2026-02-03 03:39:00 UTC

## Mutation Operators Applied

| Operator | Count |
|----------|-------|
| boolean-flip | 2 |
| numeric-boundary | 18 |
| string-literal | 6 |
| arithmetic-add-sub | 2 |
| arithmetic-mul-div | 2 |
| arithmetic-mod | 1 |
| comparison-equality | 15 |
| comparison-relational | 12 |
| boolean-and-or | 2 |

## Notes

- All mutations survived because the default testing mode only checks if mutated code parses successfully
- Use `--build` flag for full compilation testing to get more accurate kill rates
- Weekly automated runs are configured via GitHub Actions
