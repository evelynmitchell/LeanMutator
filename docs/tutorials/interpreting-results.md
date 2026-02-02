# Tutorial: Interpreting Mutation Testing Results

Learn how to analyze mutation testing results and improve your test suite.

## Understanding the Mutation Score

The **mutation score** is the primary metric:

```
Mutation Score = (Killed Mutants / Total Mutants) × 100%
```

### Score Interpretation

| Score | Interpretation |
|-------|----------------|
| 90-100% | Excellent - Very thorough test suite |
| 80-89% | Good - Strong test coverage |
| 60-79% | Fair - Some gaps in testing |
| 40-59% | Poor - Significant testing gaps |
| 0-39% | Critical - Major testing deficiencies |

## Mutation Statuses

### Killed (Good!)

The mutation caused a test to fail. This is what you want!

```
[KILLED] src/Math.lean:42 - arithmetic-add-sub: + → -
```

This means your tests correctly detect when `+` is changed to `-`.

### Survived (Needs Attention)

The mutation did NOT cause any test to fail. This indicates:

1. **Missing test case**: No test covers this code path
2. **Weak assertion**: Tests run but don't verify the result
3. **Equivalent mutant**: The mutation doesn't change behavior (rare)

```
[SURVIVED] src/Math.lean:15 - comparison-equality: = → ≠
```

**Action**: Add a test that would fail if `=` becomes `≠`.

### Timeout

The mutation caused tests to hang (infinite loop, deadlock):

```
[TIMEOUT] src/Loop.lean:8 - comparison-relational: < → ≤
```

This often indicates:

- Loop termination depends on this comparison
- The mutation created an infinite loop
- Consider this effectively "killed"

### Error

The mutation caused a build or runtime error:

```
[ERROR] src/Types.lean:20 - boolean-flip: true → false
```

Usually means:

- Type checking failed (good - caught by compiler!)
- Proof no longer valid (great for Lean!)
- These count as "killed" for scoring

## Analyzing Surviving Mutants

### Step 1: Identify Patterns

Look for clusters of surviving mutations:

```
Surviving Mutations:
  • src/Parser.lean:45 - boolean-flip: true → false
  • src/Parser.lean:47 - boolean-flip: true → false
  • src/Parser.lean:52 - comparison-equality: = → ≠
```

Pattern: Multiple survivors in `Parser.lean` → This file needs more tests.

### Step 2: Understand Each Mutation

For each surviving mutant:

1. **Read the original code**
2. **Imagine the mutated version**
3. **Ask: "What test would catch this?"**

Example:
```lean
-- Original
def isValid (x : Nat) : Bool := x > 0 && x < 100

-- Surviving mutation: && → ||
def isValid (x : Nat) : Bool := x > 0 || x < 100
```

**Question**: What input makes `(x > 0 && x < 100) ≠ (x > 0 || x < 100)`?

**Answer**: `x = 0` or `x = 100`

**New test**:
```lean
#guard isValid 0 = false
#guard isValid 100 = false
```

### Step 3: Prioritize Fixes

Not all surviving mutants are equally important:

1. **High priority**: Core business logic, security-critical code
2. **Medium priority**: Helper functions, utilities
3. **Lower priority**: Logging, formatting, debug code

## Common Surviving Patterns

### 1. Missing Boundary Tests

```lean
def isAdult (age : Nat) : Bool := age >= 18
```

Surviving: `>= → >`

**Fix**: Add test for exact boundary:
```lean
#guard isAdult 18 = true
#guard isAdult 17 = false
```

### 2. Missing Negative Tests

```lean
def findUser (id : Nat) : Option User := ...
```

Surviving: Equality mutations

**Fix**: Add test for non-existent user:
```lean
#guard findUser 99999 = none
```

### 3. Untested Error Paths

```lean
def divide (a b : Nat) : Option Nat :=
  if b == 0 then none else some (a / b)
```

Surviving: `b == 0` mutations

**Fix**: Test the error case:
```lean
#guard divide 10 0 = none
```

### 4. Boolean Expression Coverage

```lean
def canAccess (isAdmin isMember : Bool) : Bool :=
  isAdmin || isMember
```

Surviving: `|| → &&`

**Fix**: Test cases where exactly one is true:
```lean
#guard canAccess true false = true
#guard canAccess false true = true
#guard canAccess false false = false
```

## Equivalent Mutants

Sometimes mutations don't change behavior:

```lean
-- Original
def absolute (x : Int) : Int := if x < 0 then -x else x

-- Mutated (equivalent when x = 0)
def absolute (x : Int) : Int := if x <= 0 then -x else x
```

Both produce the same result for all inputs because `-0 = 0`.

**Handling equivalent mutants**:
1. Accept them as unavoidable (small percentage)
2. Consider refactoring if many equivalents exist
3. Exclude specific patterns via configuration

## Using Reports Effectively

### JSON Reports for Analysis

```bash
lake exe leanmutator mutate src/ --format json --report report.json
```

Analyze with jq:
```bash
# Files with most surviving mutants
jq '.mutations | group_by(.mutation.file) | map({file: .[0].mutation.file, survived: [.[] | select(.status == "survived")] | length}) | sort_by(.survived) | reverse' report.json

# Operators with low kill rates
jq '.mutations | group_by(.mutation.operator) | map({op: .[0].mutation.operator, killed: ([.[] | select(.status == "killed")] | length), total: length})' report.json
```

### HTML Reports for Review

```bash
lake exe leanmutator mutate src/ --format html --report report.html
```

Open in browser for interactive exploration:
- Click mutations to expand details
- See original vs mutated code
- Filter by status or file

## Tracking Progress

Monitor mutation score over time:

1. **Baseline**: Record initial score
2. **Set goals**: Incremental improvements (e.g., +5% per sprint)
3. **Track trends**: Score should increase or stay stable
4. **Investigate drops**: New code without tests lowers score

Example tracking in CI:
```yaml
- name: Check Score Trend
  run: |
    CURRENT=$(jq '.stats.score' report.json)
    PREVIOUS=$(cat .mutation-baseline 2>/dev/null || echo "0")
    if (( $(echo "$CURRENT < $PREVIOUS - 5" | bc -l) )); then
      echo "::warning::Score dropped significantly"
    fi
    echo $CURRENT > .mutation-baseline
```

## Summary

1. **High score = thorough tests** - Aim for 80%+
2. **Surviving mutants reveal gaps** - Each is a potential bug your tests miss
3. **Prioritize by impact** - Focus on critical code first
4. **Track over time** - Prevent regression in test quality
5. **Accept some equivalents** - Perfect 100% isn't always possible

## Next Steps

- Set up [CI Integration](../ci-integration.md) to track scores
- Review [Mutation Operators](../operators.md) to understand mutations
- Return to [Getting Started](../getting-started.md) for setup help
