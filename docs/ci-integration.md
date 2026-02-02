# CI Integration

This guide covers integrating LeanMutator into your CI/CD pipeline.

## GitHub Actions

### Basic Workflow

```yaml
name: Mutation Testing

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  mutation-test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install Lean
        uses: leanprover/lean-action@v1
        with:
          toolchain: leanprover/lean4:stable

      - name: Build Project
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
          retention-days: 30
```

### With Quality Gate

```yaml
name: Mutation Testing with Quality Gate

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
        id: mutation
        continue-on-error: true
        run: |
          lake exe leanmutator mutate src/ \
            --format json \
            --report mutation-report.json

      - name: Check Mutation Score
        run: |
          SCORE=$(jq '.stats.score' mutation-report.json)
          echo "Mutation Score: $SCORE%"
          if (( $(echo "$SCORE < 80" | bc -l) )); then
            echo "::error::Mutation score $SCORE% is below threshold of 80%"
            exit 1
          fi

      - name: Upload Report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: mutation-report
          path: mutation-report.json
```

### With HTML Report

```yaml
- name: Generate HTML Report
  run: |
    lake exe leanmutator mutate src/ \
      --format html \
      --report mutation-report.html

- name: Deploy Report to GitHub Pages
  uses: peaceiris/actions-gh-pages@v3
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./
    destination_dir: mutation-reports/${{ github.sha }}
```

## GitLab CI

```yaml
mutation-testing:
  stage: test
  image: leanprover/lean4:latest

  script:
    - lake build
    - lake exe leanmutator mutate src/ --format json --report mutation-report.json
    - |
      SCORE=$(cat mutation-report.json | jq '.stats.score')
      echo "Mutation Score: $SCORE%"
      if [ $(echo "$SCORE < 80" | bc) -eq 1 ]; then
        echo "Mutation score below threshold"
        exit 1
      fi

  artifacts:
    paths:
      - mutation-report.json
    reports:
      metrics: mutation-report.json
    expire_in: 1 week
```

## Exit Codes

LeanMutator uses exit codes for CI integration:

| Code | Meaning |
|------|---------|
| 0 | Success (score >= threshold) |
| 1 | Failure (score < threshold or error) |

Configure the threshold in `.leanmutator.toml`:

```toml
threshold = 80
```

## Caching

Speed up CI runs by caching the Lake build:

```yaml
- name: Cache Lake packages
  uses: actions/cache@v4
  with:
    path: |
      ~/.elan
      .lake
    key: lake-${{ runner.os }}-${{ hashFiles('lakefile.toml', 'lean-toolchain') }}

- name: Cache mutation results
  uses: actions/cache@v4
  with:
    path: .leanmutator-cache
    key: mutation-${{ github.sha }}
    restore-keys: |
      mutation-
```

## PR Comments

Add mutation results as PR comments:

```yaml
- name: Comment on PR
  if: github.event_name == 'pull_request'
  uses: actions/github-script@v7
  with:
    script: |
      const fs = require('fs');
      const report = JSON.parse(fs.readFileSync('mutation-report.json'));
      const { total, killed, survived, score } = report.stats;

      const emoji = score >= 80 ? '✅' : score >= 50 ? '⚠️' : '❌';

      const body = `## ${emoji} Mutation Testing Results

      | Metric | Value |
      |--------|-------|
      | Score | ${score}% |
      | Total | ${total} |
      | Killed | ${killed} |
      | Survived | ${survived} |

      ${survived > 0 ? `### Surviving Mutations\n\n${report.mutations
        .filter(m => m.status === 'survived')
        .slice(0, 5)
        .map(m => `- \`${m.mutation.file}\`: ${m.mutation.operator}`)
        .join('\n')}` : ''}
      `;

      github.rest.issues.createComment({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: context.issue.number,
        body: body
      });
```

## Badge Generation

Add a mutation score badge to your README:

```yaml
- name: Generate Badge
  run: |
    SCORE=$(jq '.stats.score' mutation-report.json)
    COLOR="red"
    if (( $(echo "$SCORE >= 80" | bc -l) )); then
      COLOR="brightgreen"
    elif (( $(echo "$SCORE >= 50" | bc -l) )); then
      COLOR="yellow"
    fi
    echo "![Mutation Score](https://img.shields.io/badge/mutation%20score-${SCORE}%25-${COLOR})" > badge.md
```

## Best Practices

1. **Run on main branch**: Always run mutation tests on main to track baseline
2. **Set realistic thresholds**: Start with 50%, increase gradually
3. **Cache aggressively**: Mutation testing is compute-intensive
4. **Review surviving mutants**: They often reveal real test gaps
5. **Exclude generated code**: Don't waste time mutating auto-generated files
