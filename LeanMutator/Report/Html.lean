/-
  LeanMutator - HTML Report Generation

  Visual reports with source highlighting and diff views.
-/

import LeanMutator.Mutator.Operators
import LeanMutator.Engine.Scheduler

namespace LeanMutator.Report.Html

open LeanMutator.Mutator
open LeanMutator.Engine.Scheduler

/-- Escape HTML special characters -/
def escapeHtml (s : String) : String :=
  s.replace "&" "&amp;"
   |>.replace "<" "&lt;"
   |>.replace ">" "&gt;"
   |>.replace "\"" "&quot;"
   |>.replace "'" "&#39;"

/-- Get CSS class for mutation status -/
def statusClass (status : MutationStatus) : String :=
  match status with
  | .pending => "status-pending"
  | .killed => "status-killed"
  | .survived => "status-survived"
  | .timeout => "status-timeout"
  | .error => "status-error"

/-- Get display name for status -/
def statusDisplay (status : MutationStatus) : String :=
  match status with
  | .pending => "Pending"
  | .killed => "Killed"
  | .survived => "Survived"
  | .timeout => "Timeout"
  | .error => "Error"

/-- Generate CSS styles -/
def generateCss : String := "
<style>
  :root {
    --bg-primary: #1a1a2e;
    --bg-secondary: #16213e;
    --text-primary: #eee;
    --text-secondary: #aaa;
    --accent: #0f3460;
    --success: #10b981;
    --danger: #ef4444;
    --warning: #f59e0b;
    --info: #3b82f6;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: var(--bg-primary);
    color: var(--text-primary);
    line-height: 1.6;
  }

  .container { max-width: 1200px; margin: 0 auto; padding: 2rem; }

  header {
    background: var(--bg-secondary);
    padding: 2rem;
    margin-bottom: 2rem;
    border-radius: 8px;
  }

  h1 { font-size: 2rem; margin-bottom: 0.5rem; }
  h2 { font-size: 1.5rem; margin-bottom: 1rem; color: var(--text-secondary); }

  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 1rem;
    margin-bottom: 2rem;
  }

  .stat-card {
    background: var(--bg-secondary);
    padding: 1.5rem;
    border-radius: 8px;
    text-align: center;
  }

  .stat-value { font-size: 2rem; font-weight: bold; }
  .stat-label { color: var(--text-secondary); font-size: 0.9rem; }

  .score-card .stat-value { color: var(--success); }
  .killed-card .stat-value { color: var(--success); }
  .survived-card .stat-value { color: var(--danger); }
  .timeout-card .stat-value { color: var(--warning); }
  .error-card .stat-value { color: var(--danger); }

  .mutation-list { list-style: none; }

  .mutation-item {
    background: var(--bg-secondary);
    margin-bottom: 1rem;
    border-radius: 8px;
    overflow: hidden;
  }

  .mutation-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem;
    cursor: pointer;
  }

  .mutation-header:hover { background: var(--accent); }

  .status-badge {
    padding: 0.25rem 0.75rem;
    border-radius: 4px;
    font-size: 0.8rem;
    font-weight: bold;
    text-transform: uppercase;
  }

  .status-killed { background: var(--success); color: #fff; }
  .status-survived { background: var(--danger); color: #fff; }
  .status-timeout { background: var(--warning); color: #000; }
  .status-error { background: var(--danger); color: #fff; }
  .status-pending { background: var(--info); color: #fff; }

  .mutation-details {
    padding: 1rem;
    background: var(--bg-primary);
    display: none;
  }

  .mutation-item.expanded .mutation-details { display: block; }

  .code-block {
    font-family: 'Fira Code', 'Consolas', monospace;
    padding: 1rem;
    background: #0d0d0d;
    border-radius: 4px;
    overflow-x: auto;
    margin: 0.5rem 0;
  }

  .code-original { border-left: 3px solid var(--danger); }
  .code-mutated { border-left: 3px solid var(--success); }

  .diff-label {
    font-size: 0.8rem;
    color: var(--text-secondary);
    margin-bottom: 0.25rem;
  }

  .file-path { color: var(--text-secondary); font-size: 0.9rem; }
  .operator { color: var(--info); }

  footer {
    text-align: center;
    padding: 2rem;
    color: var(--text-secondary);
    font-size: 0.9rem;
  }
</style>
"

/-- Generate JavaScript for interactivity -/
def generateJs : String := "
<script>
  document.querySelectorAll('.mutation-header').forEach(header => {
    header.addEventListener('click', () => {
      header.parentElement.classList.toggle('expanded');
    });
  });
</script>
"

/-- Generate a single mutation item HTML -/
def generateMutationItem (result : MutationResult) : String :=
  let m := result.mutation
  let statusBadge := s!"<span class=\"status-badge {statusClass result.status}\">{statusDisplay result.status}</span>"
  let filePath := escapeHtml m.file.toString
  let original := escapeHtml m.original
  let mutated := escapeHtml m.mutated
  let operator := escapeHtml m.operator

  s!"
<li class=\"mutation-item\">
  <div class=\"mutation-header\">
    <div>
      <span class=\"file-path\">{filePath}</span>
      <span class=\"operator\"> - {operator}</span>
    </div>
    {statusBadge}
  </div>
  <div class=\"mutation-details\">
    <div class=\"diff-label\">Original:</div>
    <pre class=\"code-block code-original\">{original}</pre>
    <div class=\"diff-label\">Mutated:</div>
    <pre class=\"code-block code-mutated\">{mutated}</pre>
    <p>Duration: {result.duration}ms</p>
  </div>
</li>
"

/-- Generate full HTML report -/
def generateReport (results : Array MutationResult) (stats : MutationStats)
    (title : String := "Mutation Testing Report") : String :=
  let scoreColor := if stats.score >= 80 then "success" else if stats.score >= 50 then "warning" else "danger"
  let mutationItems := String.intercalate "\n" (results.toList.map generateMutationItem)

  s!"<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>{escapeHtml title}</title>
  {generateCss}
</head>
<body>
  <div class=\"container\">
    <header>
      <h1>🧬 LeanMutator Report</h1>
      <h2>{escapeHtml title}</h2>
    </header>

    <div class=\"stats-grid\">
      <div class=\"stat-card score-card\">
        <div class=\"stat-value\">{stats.score}%</div>
        <div class=\"stat-label\">Mutation Score</div>
      </div>
      <div class=\"stat-card\">
        <div class=\"stat-value\">{stats.total}</div>
        <div class=\"stat-label\">Total Mutations</div>
      </div>
      <div class=\"stat-card killed-card\">
        <div class=\"stat-value\">{stats.killed}</div>
        <div class=\"stat-label\">Killed</div>
      </div>
      <div class=\"stat-card survived-card\">
        <div class=\"stat-value\">{stats.survived}</div>
        <div class=\"stat-label\">Survived</div>
      </div>
      <div class=\"stat-card timeout-card\">
        <div class=\"stat-value\">{stats.timedOut}</div>
        <div class=\"stat-label\">Timeout</div>
      </div>
      <div class=\"stat-card error-card\">
        <div class=\"stat-value\">{stats.errors}</div>
        <div class=\"stat-label\">Errors</div>
      </div>
    </div>

    <h2>Mutations</h2>
    <ul class=\"mutation-list\">
      {mutationItems}
    </ul>

    <footer>
      Generated by LeanMutator | {stats.totalTime}ms total
    </footer>
  </div>
  {generateJs}
</body>
</html>
"

/-- Write HTML report to file -/
def writeReport (path : System.FilePath) (results : Array MutationResult)
    (stats : MutationStats) (title : String := "Mutation Testing Report") : IO Unit := do
  let content := generateReport results stats title
  IO.FS.writeFile path content

end LeanMutator.Report.Html
