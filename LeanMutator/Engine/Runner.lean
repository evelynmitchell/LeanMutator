/-
  LeanMutator - Test Execution via Lake

  This module handles:
  - Writing mutated source to temp files
  - Running Lake build to test mutations
  - Parsing build output for pass/fail
-/

import Lean
import LeanMutator.Mutator.Operators
import LeanMutator.Engine.Syntax

namespace LeanMutator.Engine.Runner

open LeanMutator.Mutator
open LeanMutator.Engine.Syntax

/-- Configuration for the test runner -/
structure RunnerConfig where
  /-- Timeout for each mutation test (milliseconds) -/
  timeout : Nat := 60000
  /-- Whether to keep temp files after running -/
  keepTempFiles : Bool := false
  /-- Custom test command (default: lake build) -/
  testCommand : Option String := none
  /-- Working directory for lake commands -/
  workDir : Option System.FilePath := none
  deriving Repr, Inhabited

/-- Result of running a single mutation test -/
structure TestRunResult where
  /-- Whether the build/test succeeded -/
  success : Bool
  /-- Exit code -/
  exitCode : UInt32
  /-- Standard output -/
  stdout : String
  /-- Standard error -/
  stderr : String
  /-- Execution time in milliseconds -/
  duration : Nat
  deriving Repr, Inhabited

/-- Create a temp directory for mutation testing -/
def createTempDir : IO System.FilePath := do
  let tmpBase := "/tmp/leanmutator"
  IO.FS.createDirAll tmpBase
  let timestamp ← IO.monoMsNow
  let dir := s!"{tmpBase}/mutation_{timestamp}"
  IO.FS.createDirAll dir
  return dir

/-- Write mutated source to a temp file -/
def writeMutatedSource (source : String) (originalPath : System.FilePath)
    (tempDir : System.FilePath) : IO System.FilePath := do
  let fileName := originalPath.fileName.getD "mutated.lean"
  let tempPath := tempDir / fileName
  IO.FS.writeFile tempPath source
  return tempPath

/-- Run a shell command with timeout -/
def runCommand (cmd : String) (args : Array String)
    (workDir : Option System.FilePath := none)
    (timeout : Nat := 60000) : IO TestRunResult := do
  let startTime ← IO.monoMsNow

  let proc ← IO.Process.spawn {
    cmd := cmd
    args := args
    cwd := workDir
    stdout := .piped
    stderr := .piped
  }

  -- Wait for process with timeout
  -- Note: Lean's IO.Process doesn't have native timeout, so we approximate
  let stdout ← proc.stdout.readToEnd
  let stderr ← proc.stderr.readToEnd
  let exitCode ← proc.wait

  let endTime ← IO.monoMsNow
  let duration := endTime - startTime

  return {
    success := exitCode == 0
    exitCode := exitCode
    stdout := stdout
    stderr := stderr
    duration := duration
  }

/-- Run lake build on a file to check if mutation compiles -/
def runLakeBuild (file : System.FilePath) (config : RunnerConfig)
    : IO TestRunResult := do
  let workDir := config.workDir.getD (file.parent.getD ".")
  runCommand "lake" #["build"] (some workDir) config.timeout

/-- Run lake test to check if tests pass -/
def runLakeTest (config : RunnerConfig) : IO TestRunResult := do
  let workDir := config.workDir.getD "."
  let cmd := config.testCommand.getD "lake test"
  let parts := cmd.splitOn " "
  match parts with
  | [] => return { success := false, exitCode := 1, stdout := "", stderr := "Empty command", duration := 0 }
  | cmd :: args =>
    runCommand cmd args.toArray (some workDir) config.timeout

/-- Test a single mutation -/
def testMutation (mutation : Mutation) (originalSource : String)
    (config : RunnerConfig) : IO MutationResult := do
  let startTime ← IO.monoMsNow

  -- Apply the mutation to get mutated source
  let mutatedSource := applyMutation originalSource mutation

  -- Create temp directory and write mutated file
  let tempDir ← createTempDir
  let tempFile ← writeMutatedSource mutatedSource mutation.file tempDir

  -- Copy the file to the original location for testing
  -- (In a real implementation, we'd set up a proper isolated environment)
  let backupPath := mutation.file.toString ++ ".bak"
  IO.FS.writeFile backupPath originalSource

  try
    -- Replace original with mutated
    IO.FS.writeFile mutation.file mutatedSource

    -- Run build/test
    let result ← runLakeBuild mutation.file config

    let endTime ← IO.monoMsNow
    let duration := endTime - startTime

    -- Determine mutation status
    let status := if !result.success then
      -- Build failed = mutation killed
      MutationStatus.killed
    else if result.duration >= config.timeout then
      MutationStatus.timeout
    else
      -- Build succeeded = mutation survived
      MutationStatus.survived

    -- Restore original
    IO.FS.writeFile mutation.file originalSource

    -- Clean up temp files
    if !config.keepTempFiles then
      IO.FS.removeFile tempFile
      try IO.FS.removeDir tempDir catch _ => pure ()

    return {
      mutation := mutation
      status := status
      duration := duration
      message := if status == .killed then result.stderr else ""
    }
  catch e =>
    -- Restore original on error
    try
      let backup ← IO.FS.readFile backupPath
      IO.FS.writeFile mutation.file backup
    catch _ => pure ()

    let endTime ← IO.monoMsNow
    return {
      mutation := mutation
      status := .error
      duration := endTime - startTime
      message := s!"Error: {e}"
    }

/-- Test a mutation in isolation (without modifying original file) -/
def testMutationIsolated (mutation : Mutation) (originalSource : String)
    (config : RunnerConfig) : IO MutationResult := do
  let startTime ← IO.monoMsNow

  -- Apply the mutation
  let mutatedSource := applyMutation originalSource mutation

  -- Create isolated temp directory
  let tempDir ← createTempDir
  let _ ← writeMutatedSource mutatedSource mutation.file tempDir

  -- For isolated testing, we just check if the mutated code parses
  -- (Full build testing requires more setup)
  let parseResult ← parseSource mutatedSource mutation.file.toString

  let endTime ← IO.monoMsNow
  let duration := endTime - startTime

  let status := match parseResult with
    | .ok _ => .survived  -- Parsed OK, would need full build test
    | .error _ => .killed  -- Parse error = killed

  -- Clean up
  if !config.keepTempFiles then
    try IO.FS.removeDir tempDir catch _ => pure ()

  return {
    mutation := mutation
    status := status
    duration := duration
    message := match parseResult with
      | .ok _ => "Mutation parses successfully"
      | .error e => e
  }

/-- Run all mutations and collect results -/
def runAllMutations (mutations : Array Mutation) (originalSource : String)
    (config : RunnerConfig) (isolated : Bool := true) : IO (Array MutationResult) := do
  let mut results : Array MutationResult := #[]

  for mutation in mutations do
    let result ← if isolated then
      testMutationIsolated mutation originalSource config
    else
      testMutation mutation originalSource config
    results := results.push result

  return results

end LeanMutator.Engine.Runner
