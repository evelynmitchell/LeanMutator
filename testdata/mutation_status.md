# Mutation Testing Status

Last updated: 2026-02-03 03:50:07 UTC

## Summary

| Metric | Value |
|--------|-------|
| Files Scanned | 16 |
| Total Mutations | 104+ |
| Killed | 0 |
| Survived | 104+ |
| Timed Out | 0 |
| Errors | 0 |
| **Duration** | **52s** |

## Test Configuration

- **Target**: `testdata/`
- **Mode**: Isolated (parse-only)
- **Generator**: LeanMutator
- **Started**: 2026-02-03 03:49:15 UTC
- **Finished**: 2026-02-03 03:50:07 UTC

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
