# Mutation Testing Status

Last updated: 2026-02-22 00:22:08 UTC

## Summary

| Metric | Value |
|--------|-------|
| Score | **94.805195%** |
| Total Mutations | 154 |
| Killed | 146 |
| Survived | 8 |
| Timed Out | 0 |
| Errors | 0 |
| **Duration** | **1m 38s** |

## Test Configuration

- **Target**: `testdata/TestLib.lean`
- **Mode**: Build (full compilation)
- **Generator**: LeanMutator
- **Started**: 2026-02-22 00:20:30 UTC
- **Finished**: 2026-02-22 00:22:08 UTC

## Notes

- Automated weekly run via GitHub Actions
- Tests use `#guard` compile-time assertions
- Mutations are tested by full compilation (`--build` flag)
