# Mutation Testing Status

Last updated: 2026-02-03

## Summary

| Metric | Value |
|--------|-------|
| Score | 0.00% |
| Total Mutations | 59 |
| Killed | 0 |
| Survived | 59 |
| Timed Out | 0 |
| Errors | 0 |
| Total Time | 35ms |

## Test Configuration

- **Target**: `testdata/tests/Sample.lean`
- **Mode**: Isolated (parse-only)
- **Generator**: LeanMutator

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
