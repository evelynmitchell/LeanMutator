# Mutation Testing Status

Last updated: 2026-02-08 00:27:47 UTC

## Summary

| Metric | Value |
|--------|-------|
| Score | **94.805195%** |
| Total Mutations | 154 |
| Killed | 146 |
| Survived | 8 |
| Timed Out | 0 |
| Errors | 0 |
| **Duration** | **1m 37s** |

## Test Configuration

- **Target**: `testdata/TestLib.lean`
- **Mode**: Build (full compilation)
- **Generator**: LeanMutator
- **Started**: 2026-02-08 00:26:10 UTC
- **Finished**: 2026-02-08 00:27:47 UTC

## Notes

- Automated weekly run via GitHub Actions
- Tests use `#guard` compile-time assertions
- Mutations are tested by full compilation (`--build` flag)
