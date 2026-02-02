/-
  LeanMutator - Parallel Mutation Scheduling

  This module handles:
  - Parallel execution of mutation tests
  - Work distribution across workers
  - Progress tracking
-/

import Lean
import LeanMutator.Mutator.Operators
import LeanMutator.Engine.Runner

namespace LeanMutator.Engine.Scheduler

open LeanMutator.Mutator
open LeanMutator.Engine.Runner

/-- Simple association list for file -> source mapping -/
abbrev SourceMap := Array (System.FilePath × String)

/-- Look up a file in the source map -/
def SourceMap.find? (m : SourceMap) (path : System.FilePath) : Option String :=
  m.findSome? fun (p, s) => if p == path then some s else none

/-- Configuration for the scheduler -/
structure SchedulerConfig where
  /-- Number of parallel workers -/
  numWorkers : Nat := 4
  /-- Runner configuration -/
  runnerConfig : RunnerConfig := {}
  /-- Callback for progress updates -/
  onProgress : Option (Nat → Nat → IO Unit) := none
  deriving Inhabited

/-- Statistics for a mutation run -/
structure MutationStats where
  /-- Total mutations tested -/
  total : Nat := 0
  /-- Mutations that were killed (test failed) -/
  killed : Nat := 0
  /-- Mutations that survived (test passed) -/
  survived : Nat := 0
  /-- Mutations that timed out -/
  timedOut : Nat := 0
  /-- Mutations that caused errors -/
  errors : Nat := 0
  /-- Total execution time in milliseconds -/
  totalTime : Nat := 0
  deriving Repr, Inhabited

/-- Calculate mutation score as a percentage -/
def MutationStats.score (stats : MutationStats) : Float :=
  if stats.total == 0 then 100.0
  else
    let effective := stats.total - stats.errors
    if effective == 0 then 100.0
    else (stats.killed.toFloat / effective.toFloat) * 100.0

/-- Pretty print mutation statistics -/
def MutationStats.toString (stats : MutationStats) : String :=
  let score := stats.score
  s!"Mutation Score: {score}%\n" ++
  s!"  Total:    {stats.total}\n" ++
  s!"  Killed:   {stats.killed}\n" ++
  s!"  Survived: {stats.survived}\n" ++
  s!"  Timeout:  {stats.timedOut}\n" ++
  s!"  Errors:   {stats.errors}\n" ++
  s!"  Time:     {stats.totalTime}ms"

instance : ToString MutationStats := ⟨MutationStats.toString⟩

/-- Collect statistics from results -/
def collectStats (results : Array MutationResult) : MutationStats := Id.run do
  let mut stats : MutationStats := {}
  stats := { stats with total := results.size }

  for result in results do
    match result.status with
    | .killed => stats := { stats with killed := stats.killed + 1 }
    | .survived => stats := { stats with survived := stats.survived + 1 }
    | .timeout => stats := { stats with timedOut := stats.timedOut + 1 }
    | .error => stats := { stats with errors := stats.errors + 1 }
    | .pending => pure ()
    stats := { stats with totalTime := stats.totalTime + result.duration }

  return stats

/-- Progress tracker -/
structure ProgressTracker where
  total : IO.Ref Nat
  completed : IO.Ref Nat
  callback : Option (Nat → Nat → IO Unit)

/-- Create a new progress tracker -/
def ProgressTracker.new (total : Nat) (callback : Option (Nat → Nat → IO Unit))
    : IO ProgressTracker := do
  let totalRef ← IO.mkRef total
  let completedRef ← IO.mkRef 0
  return { total := totalRef, completed := completedRef, callback := callback }

/-- Report progress -/
def ProgressTracker.report (tracker : ProgressTracker) : IO Unit := do
  let completed ← tracker.completed.get
  let total ← tracker.total.get
  match tracker.callback with
  | some cb => cb completed total
  | none => pure ()

/-- Increment completed count -/
def ProgressTracker.increment (tracker : ProgressTracker) : IO Unit := do
  let current ← tracker.completed.get
  tracker.completed.set (current + 1)
  tracker.report

/-- Run mutations sequentially with progress tracking -/
def runSequential (mutations : Array Mutation) (sources : SourceMap)
    (config : SchedulerConfig) : IO (Array MutationResult) := do
  let tracker ← ProgressTracker.new mutations.size config.onProgress
  let mut results : Array MutationResult := #[]

  for mutation in mutations do
    let source := sources.find? mutation.file |>.getD ""
    let result ← testMutationIsolated mutation source config.runnerConfig
    results := results.push result
    tracker.increment

  return results

/-- Run mutations in parallel using IO.asTask -/
def runParallel (mutations : Array Mutation) (sources : SourceMap)
    (config : SchedulerConfig) : IO (Array MutationResult) := do
  -- For simplicity, we'll run sequentially but could use IO.asTask for parallelism
  -- True parallelism would require careful handling of file system state
  runSequential mutations sources config

/-- Main scheduler entry point -/
def schedule (mutations : Array Mutation) (sources : SourceMap)
    (config : SchedulerConfig) : IO (Array MutationResult × MutationStats) := do
  let startTime ← IO.monoMsNow

  -- Run mutations
  let results ← if config.numWorkers <= 1 then
    runSequential mutations sources config
  else
    runParallel mutations sources config

  let endTime ← IO.monoMsNow

  -- Collect stats
  let stats := collectStats results
  let stats := { stats with totalTime := endTime - startTime }

  return (results, stats)

end LeanMutator.Engine.Scheduler
