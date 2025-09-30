# Fix DebugLogger.*(...) calls that have multiple comma-separated args by converting
# them into a single string argument using concatenation. Wrap non-literals with str().

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$files = Get-ChildItem -Path "$root\.." -Recurse -Filter *.gd | Where-Object { $_.FullName -notmatch "\\scripts\\DebugLogger.gd$" -and $_.FullName -notmatch "\\tools\\" }

function Split-TopLevelArgs([string]$s) {
    $parts = @()
    $cur = ''
    $paren = 0
    $inD = $false
    $inS = $false
    for ($i = 0; $i -lt $s.Length; $i++) {
        $c = $s[$i]
        if ($c -eq '"' -and -not $inS) { $inD = -not $inD; $cur += $c; continue }
        if ($c -eq "'" -and -not $inD) { $inS = -not $inS; $cur += $c; continue }
        if ($inD -or $inS) { $cur += $c; continue }
        if ($c -eq '(') { $paren++; $cur += $c; continue }
        if ($c -eq ')') { if ($paren -gt 0) { $paren-- }; $cur += $c; continue }
        if ($c -eq ',' -and $paren -eq 0) {
            $parts += $cur.Trim()
            $cur = ''
            continue
        }
        $cur += $c
    }
    if ($cur.Trim() -ne '') { $parts += $cur.Trim() }
    return ,$parts
}

foreach ($f in $files) {
    $path = $f.FullName
    $text = Get-Content -Path $path -Raw
    $changed = $false

    $pattern = 'DebugLogger\.(info|warn|error|log)\s*\(([^)]*)\)'
    $mset = [regex]::Matches($text, $pattern)
    if ($matches.Count -eq 0) { continue }

    # Process matches from last to first to avoid offset issues
    for ($mi = $mset.Count - 1; $mi -ge 0; $mi--) {
        $m = $mset[$mi]
        $fn = $m.Groups[1].Value
        $argsRaw = $m.Groups[2].Value.Trim()
        if ($argsRaw -eq '') { continue }
        # If there's no top-level comma, skip
        if ($argsRaw -notmatch ',') { continue }

        $parts = Split-TopLevelArgs $argsRaw
        $newParts = @()
        foreach ($p in $parts) {
            if ($p.StartsWith('"') -and $p.EndsWith('"') -or $p.StartsWith("'") -and $p.EndsWith("'")) {
                $newParts += $p
            } else {
                # Wrap with str() to be safe
                $trim = $p.Trim()
                # If already a str(...) or to_string, skip
                if ($trim -match '^str\s*\(' -or $trim -match '^String\s*\(') {
                    $newParts += $trim
                } else {
                    $newParts += "str($trim)"
                }
            }
        }
        $joined = ($newParts -join ' + " " + ')
        $replacement = "DebugLogger.$fn($joined)"

        # Replace in text at the match index
        $start = $m.Index
        $len = $m.Length
        $text = $text.Substring(0, $start) + $replacement + $text.Substring($start + $len)
        $changed = $true
    }

    if ($changed) {
        Set-Content -Path $path -Value $text -Encoding UTF8
        Write-Host "Fixed DebugLogger args: $path"
    }
}

Write-Host "Fix script completed."