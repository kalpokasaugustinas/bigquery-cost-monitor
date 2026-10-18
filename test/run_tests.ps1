# test runner for the bigquery cost report
# usage:
#   .\test\run_tests.ps1 -step setup    # build test tables (run once)
#   .\test\run_tests.ps1 -step usage    # run the usage queries, one job each
#   .\test\run_tests.ps1 -step report   # run the script from the page, save the csv result
param(
  [ValidateSet('setup', 'usage', 'report')]
  [string]$step = 'report'
)

# project and safety limit: no single query may bill more than 5 gb
$project = 'bq-cost-monitor-project'
$max_bytes = 5000000000
$root = split-path -parent $psscriptroot

# runs one sql text through bq
# the text goes to a temp file and is fed in by cmd, because a powershell pipe
# adds a byte order mark that bigquery rejects
function invoke-bq([string]$sql, [string]$format = 'pretty') {
  $temp_file = join-path $env:temp 'bq_cost_monitor_query.sql'
  [system.io.file]::writealltext($temp_file, $sql, (new-object system.text.utf8encoding $false))
  cmd /c "bq --quiet query --project_id=$project --use_legacy_sql=false --maximum_bytes_billed=$max_bytes --format=$format < `"$temp_file`""
}

if ($step -eq 'setup') {
  # the setup file runs as one multi-statement script
  invoke-bq (get-content "$root\test\01_setup_test_data.sql" -raw) 'none'
}

if ($step -eq 'usage') {
  # drop comment lines first: bigquery only serves a query from cache when the
  # text is identical, and the numbered comments would make every text unique
  $sql_lines = get-content "$root\test\02_generate_usage.sql" | where-object { $_ -notmatch '^\s*--' }
  # split on semicolons so every statement becomes its own job
  $statements = ($sql_lines -join "`n") -split ";\s*\n" |
    where-object { $_ -match '\bselect\b' } |
    # trim spaces and the last semicolon so repeated statements are identical
    foreach-object { $_.trim().trimend(';').trim() }
  $i = 0
  foreach ($statement in $statements) {
    $i++
    write-host "--- usage query $i of $($statements.count)"
    invoke-bq $statement 'none'
  }
}

if ($step -eq 'report') {
  # take the sql script out of the page (the only copy) and run it
  $page = [system.io.file]::readalltext("$root\bigquery-cost-report.html")
  $sql = [regex]::match($page, '(?s)<script type="text/plain" id="cost-report-sql">(.*?)</script>').groups[1].value
  # save its result as csv, like a user would from the console
  $output = invoke-bq $sql 'csv'
  # bq also prints the dynamic sql it runs, keep only the result (header + one row)
  $text = $output -join "`n"
  $text = $text.substring($text.lastindexof("cost_report`n"))
  $out_file = "$root\test\cost_report.csv"
  [system.io.file]::writealltext($out_file, $text, (new-object system.text.utf8encoding $false))
  write-host "saved $out_file, drop it onto bigquery-cost-report.html"
}
