/-
  LeanMutator - Console Output

  Terminal output formatting for mutation results.
-/

import LeanMutator.Mutator.Operators
import LeanMutator.Engine.Scheduler

namespace LeanMutator.Report.Console

open LeanMutator.Mutator
open LeanMutator.Engine.Scheduler

/-- ANSI color codes -/
def red : String := "\x1b[31m"
def green : String := "\x1b[32m"
def yellow : String := "\x1b[33m"
def blue : String := "\x1b[34m"
def bold : String := "\x1b[1m"
def reset : String := "\x1b[0m"

/-- Format a mutation status with color -/
def formatStatus (status : MutationStatus) (useColor : Bool := true) : String :=
  if useColor then
    match status with
    | .pending => s!"{yellow}PENDING{reset}"
    | .killed => s!"{green}KILLED{reset}"
    | .survived => s!"{red}SURVIVED{reset}"
    | .timeout => s!"{yellow}TIMEOUT{reset}"
    | .error => s!"{red}ERROR{reset}"
  else
    toString status |>.toUpper

/-- Format a single mutation result -/
def formatResult (result : MutationResult) (useColor : Bool := true)
    (verbose : Bool := false) : String :=
  let status := formatStatus result.status useColor
  let loc := s!"{result.mutation.file}:{result.mutation.location.startCol}"
  let op := result.mutation.operator

  let header := s!"[{status}] {loc} - {op}"

  if verbose then
    let original := result.mutation.original
    let mutated := result.mutation.mutated
    s!"{header}\n  Original: {original}\n  Mutated:  {mutated}\n  Time: {result.duration}ms"
  else
    header

/-- Format summary statistics -/
def formatStats (stats : MutationStats) (useColor : Bool := true) : String :=
  let score := stats.score
  let scoreStr := if useColor then
    if score >= 80.0 then s!"{green}{score}%{reset}"
    else if score >= 50.0 then s!"{yellow}{score}%{reset}"
    else s!"{red}{score}%{reset}"
  else
    s!"{score}%"

  let header := if useColor then s!"{bold}Mutation Testing Results{reset}" else "Mutation Testing Results"

  s!"{header}\n" ++
  s!"══════════════════════════════\n" ++
  s!"Score: {scoreStr}\n" ++
  s!"──────────────────────────────\n" ++
  s!"Total Mutations: {stats.total}\n" ++
  s!"  ✓ Killed:   {stats.killed}\n" ++
  s!"  ✗ Survived: {stats.survived}\n" ++
  s!"  ⏱ Timeout:  {stats.timedOut}\n" ++
  s!"  ⚠ Errors:   {stats.errors}\n" ++
  s!"──────────────────────────────\n" ++
  s!"Total Time: {stats.totalTime}ms"

/-- Print a progress bar -/
def formatProgress (completed : Nat) (total : Nat) (width : Nat := 40)
    (useColor : Bool := true) : String :=
  if total == 0 then
    "No mutations to test"
  else
    let percent := (completed * 100) / total
    let filled := (completed * width) / total
    let empty := width - filled

    let bar := String.ofList (List.replicate filled '█') ++
               String.ofList (List.replicate empty '░')

    let coloredBar := if useColor then s!"{green}{bar}{reset}" else bar

    s!"[{coloredBar}] {percent}% ({completed}/{total})"

/-- Print results to console -/
def printResults (results : Array MutationResult) (stats : MutationStats)
    (verbose : Bool := false) (useColor : Bool := true) : IO Unit := do
  -- Print individual results
  if verbose then
    IO.println "\nDetailed Results:"
    IO.println "─────────────────"
    for result in results do
      IO.println (formatResult result useColor verbose)

  -- Print summary
  IO.println ""
  IO.println (formatStats stats useColor)

  -- Print survived mutations (always show these as they indicate weak tests)
  let survived := results.filter (·.status == .survived)
  if survived.size > 0 then
    IO.println ""
    IO.println (if useColor then s!"{red}{bold}Surviving Mutations (weak tests):{reset}" else "Surviving Mutations (weak tests):")
    for result in survived do
      IO.println s!"  • {formatResult result useColor false}"

/-- Print a single line progress update -/
def printProgress (completed : Nat) (total : Nat) (useColor : Bool := true) : IO Unit := do
  let progressBar := formatProgress completed total 30 useColor
  -- Use carriage return to overwrite line
  IO.print s!"\r{progressBar}"
  if completed == total then IO.println ""

/-- Create a progress callback for the scheduler -/
def progressCallback (useColor : Bool := true) : Nat → Nat → IO Unit :=
  fun completed total => printProgress completed total useColor

end LeanMutator.Report.Console
