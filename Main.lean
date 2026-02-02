/-
  LeanMutator - CLI Entry Point

  Command-line interface for mutation testing Lean 4 projects.
-/

import LeanMutator

open LeanMutator
open LeanMutator.Mutator
open LeanMutator.Engine.Syntax
open LeanMutator.Engine.Runner
open LeanMutator.Engine.Scheduler
open LeanMutator.Report

/-- Output format for results -/
inductive OutputFormat
  | console
  | json
  | html
  deriving Repr, Inhabited

def OutputFormat.fromString (s : String) : OutputFormat :=
  match s.toLower with
  | "json" => .json
  | "html" => .html
  | _ => .console

/-- Configuration parsed from CLI arguments -/
structure CliConfig where
  files : Array System.FilePath
  operators : Array String
  exclude : Array String
  timeout : Nat
  parallel : Nat
  output : OutputFormat
  reportPath : Option System.FilePath
  verbose : Bool
  useColor : Bool
  isolated : Bool
  deriving Repr, Inhabited

/-- Default configuration -/
def CliConfig.default : CliConfig := {
  files := #[]
  operators := #[]
  exclude := #[]
  timeout := 60000
  parallel := 1
  output := .console
  reportPath := none
  verbose := false
  useColor := true
  isolated := true
}

/-- Run mutation testing on a single file -/
def mutateFile (file : System.FilePath) (config : CliConfig) : IO (Array MutationResult × MutationStats) := do
  -- Read source file
  let source ← IO.FS.readFile file

  -- Parse the file
  let parseResult ← parseFile file
  let stx ← match parseResult with
    | .ok stx => pure stx
    | .error e =>
      IO.eprintln s!"Error parsing {file}: {e}"
      return (#[], {})

  -- Get operators to use
  let registry := defaultRegistry
  let operators := if config.operators.isEmpty then
    registry.all
  else
    registry.getByNames config.operators

  if operators.isEmpty then
    IO.eprintln "No mutation operators selected"
    return (#[], {})

  -- Create traversal context and find mutations
  let ctx ← TraversalContext.new source file operators
  let points ← findMutationPoints ctx stx
  let mutations ← generateMutations ctx points

  if config.verbose then
    IO.println s!"Found {mutations.size} mutation points in {file}"

  -- Configure runner
  let runnerConfig : RunnerConfig := {
    timeout := config.timeout
    keepTempFiles := false
  }

  let schedulerConfig : SchedulerConfig := {
    numWorkers := config.parallel
    runnerConfig := runnerConfig
    onProgress := if config.useColor then some (Console.progressCallback true) else none
  }

  -- Create source map
  let sources : SourceMap := #[(file, source)]

  -- Run mutations
  let (results, stats) ← schedule mutations sources schedulerConfig

  return (results, stats)

/-- Run mutation testing on multiple files -/
def mutateFiles (files : Array System.FilePath) (config : CliConfig)
    : IO (Array MutationResult × MutationStats) := do
  let mut allResults : Array MutationResult := #[]
  let mut totalStats : MutationStats := {}

  for file in files do
    -- Skip excluded files
    let fileName := file.toString
    let excluded := config.exclude.any (fun pat => (fileName.splitOn pat).length > 1)
    if excluded then
      if config.verbose then
        IO.println s!"Skipping excluded file: {file}"
      continue

    -- Check if file exists
    let fileExists ← file.pathExists
    if !fileExists then
      IO.eprintln s!"File not found: {file}"
      continue

    IO.println s!"Mutating: {file}"
    let (results, stats) ← mutateFile file config

    allResults := allResults ++ results
    totalStats := {
      total := totalStats.total + stats.total
      killed := totalStats.killed + stats.killed
      survived := totalStats.survived + stats.survived
      timedOut := totalStats.timedOut + stats.timedOut
      errors := totalStats.errors + stats.errors
      totalTime := totalStats.totalTime + stats.totalTime
    }

  return (allResults, totalStats)

/-- Find all .lean files in a directory -/
partial def findLeanFiles (dir : System.FilePath) : IO (Array System.FilePath) := do
  let mut files : Array System.FilePath := #[]
  let entries ← dir.readDir

  for entry in entries do
    let path := entry.path
    if ← path.isDir then
      -- Skip hidden directories and .lake
      let name := entry.fileName
      if !name.startsWith "." && name != ".lake" then
        let subFiles ← findLeanFiles path
        files := files ++ subFiles
    else if path.extension == some "lean" then
      files := files.push path

  return files

/-- Print usage information -/
def printUsage : IO Unit := do
  IO.println "LeanMutator - Mutation testing for Lean 4"
  IO.println ""
  IO.println "USAGE:"
  IO.println "  leanmutator <command> [options] [files...]"
  IO.println ""
  IO.println "COMMANDS:"
  IO.println "  mutate <files...>    Run mutation testing on files or directories"
  IO.println "  list-operators       List all available mutation operators"
  IO.println "  init                 Create default .leanmutator.toml"
  IO.println "  help                 Show this help message"
  IO.println ""
  IO.println "OPTIONS for mutate:"
  IO.println "  -o, --operators STR  Comma-separated list of operators"
  IO.println "  -e, --exclude STR    Comma-separated patterns to exclude"
  IO.println "  -t, --timeout N      Timeout per mutation (ms, default: 60000)"
  IO.println "  -p, --parallel N     Number of parallel workers (default: 1)"
  IO.println "  -f, --format FMT     Output: console, json, html (default: console)"
  IO.println "  -r, --report PATH    Path for json/html report"
  IO.println "  -v, --verbose        Show detailed output"
  IO.println "  --no-color           Disable colored output"
  IO.println ""
  IO.println "EXAMPLES:"
  IO.println "  leanmutator mutate src/MyFile.lean"
  IO.println "  leanmutator mutate src/ --format json --report report.json"
  IO.println "  leanmutator list-operators"

/-- Parse command line arguments -/
def parseArgs (args : List String) : IO (String × CliConfig × Array String) := do
  let mut config := CliConfig.default
  let mut files : Array String := #[]
  let mut command := "help"
  let mut i := 0
  let argArr := args.toArray

  if argArr.size > 0 then
    command := argArr[0]!
    i := 1

  while i < argArr.size do
    let arg := argArr[i]!
    if arg == "-o" || arg == "--operators" then
      if i + 1 < argArr.size then
        config := { config with operators := argArr[i+1]!.splitOn "," |>.toArray }
        i := i + 2
      else
        i := i + 1
    else if arg == "-e" || arg == "--exclude" then
      if i + 1 < argArr.size then
        config := { config with exclude := argArr[i+1]!.splitOn "," |>.toArray }
        i := i + 2
      else
        i := i + 1
    else if arg == "-t" || arg == "--timeout" then
      if i + 1 < argArr.size then
        config := { config with timeout := argArr[i+1]!.toNat?.getD 60000 }
        i := i + 2
      else
        i := i + 1
    else if arg == "-p" || arg == "--parallel" then
      if i + 1 < argArr.size then
        config := { config with parallel := argArr[i+1]!.toNat?.getD 1 }
        i := i + 2
      else
        i := i + 1
    else if arg == "-f" || arg == "--format" then
      if i + 1 < argArr.size then
        config := { config with output := OutputFormat.fromString argArr[i+1]! }
        i := i + 2
      else
        i := i + 1
    else if arg == "-r" || arg == "--report" then
      if i + 1 < argArr.size then
        config := { config with reportPath := some ⟨argArr[i+1]!⟩ }
        i := i + 2
      else
        i := i + 1
    else if arg == "-v" || arg == "--verbose" then
      config := { config with verbose := true }
      i := i + 1
    else if arg == "--no-color" then
      config := { config with useColor := false }
      i := i + 1
    else if !arg.startsWith "-" then
      files := files.push arg
      i := i + 1
    else
      i := i + 1

  return (command, config, files)

/-- Run the mutate command -/
def runMutate (config : CliConfig) (fileArgs : Array String) : IO UInt32 := do
  if fileArgs.isEmpty then
    IO.eprintln "Error: No files specified"
    IO.eprintln "Usage: leanmutator mutate <file|directory>..."
    return 1

  -- Collect all files to mutate
  let mut files : Array System.FilePath := #[]
  for arg in fileArgs do
    let path : System.FilePath := ⟨arg⟩
    if ← path.isDir then
      let dirFiles ← findLeanFiles path
      files := files ++ dirFiles
    else
      files := files.push path

  if files.isEmpty then
    IO.eprintln "No .lean files found"
    return 1

  if config.verbose then
    IO.println s!"Found {files.size} files to mutate"

  -- Run mutation testing
  let (results, stats) ← mutateFiles files { config with files := files }

  -- Output results
  match config.output with
  | .json =>
    let jsonStr := Json.generateReportString results stats
    match config.reportPath with
    | some path =>
      IO.FS.writeFile path jsonStr
      IO.println s!"JSON report written to {path}"
    | none =>
      IO.println jsonStr
  | .html =>
    let htmlStr := Html.generateReport results stats
    match config.reportPath with
    | some path =>
      IO.FS.writeFile path htmlStr
      IO.println s!"HTML report written to {path}"
    | none =>
      IO.println htmlStr
  | .console =>
    Console.printResults results stats config.verbose config.useColor

  -- Return exit code based on mutation score
  if stats.score >= 80.0 then
    return 0
  else
    return 1

/-- Run the list-operators command -/
def runListOperators (verbose : Bool) : IO UInt32 := do
  let registry := defaultRegistry

  IO.println "Available Mutation Operators:"
  IO.println "═══════════════════════════════"

  for op in registry.all do
    if verbose then
      IO.println s!"\n{op.name}"
      IO.println s!"  {op.description}"
    else
      IO.println s!"  • {op.name}"

  IO.println ""
  IO.println s!"Total: {registry.all.size} operators"
  return 0

/-- Run the init command -/
def runInit : IO UInt32 := do
  let configPath : System.FilePath := ".leanmutator.toml"

  if ← configPath.pathExists then
    IO.eprintln s!"{configPath} already exists"
    return 1

  let defaultConfig := "# LeanMutator Configuration

# Mutation operators to use (empty = all)
operators = []

# File patterns to exclude from mutation
exclude = [\"tests/\", \"*Test.lean\", \".lake/\"]

# Timeout per mutation in milliseconds
timeout = 60000

# Number of parallel workers
parallel = 1

# Output format: \"console\", \"json\", \"html\"
output = \"console\"

# Minimum mutation score threshold (0-100)
threshold = 80
"

  IO.FS.writeFile configPath defaultConfig
  IO.println s!"Created {configPath}"
  return 0

/-- Main entry point -/
def main (args : List String) : IO UInt32 := do
  let (command, config, files) ← parseArgs args

  match command with
  | "mutate" => runMutate config files
  | "list-operators" => runListOperators config.verbose
  | "init" => runInit
  | "help" | "--help" | "-h" =>
    printUsage
    return 0
  | _ =>
    if files.isEmpty && command != "help" then
      -- Treat command as a file if no subcommand recognized
      runMutate config #[command]
    else
      IO.eprintln s!"Unknown command: {command}"
      printUsage
      return 1
