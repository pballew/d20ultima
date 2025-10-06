$dllPath = Join-Path $PSScriptRoot '..\.godot\mono\temp\bin\Debug\d20ultima.dll'
Write-Host "Inspecting assembly: $dllPath"
if (-not (Test-Path $dllPath)) { Write-Host "Assembly not found: $dllPath"; exit 1 }
try {
    $asm = [Reflection.Assembly]::LoadFrom($dllPath)
    try {
        $types = $asm.GetTypes()
        Write-Host "Loaded types:" 
        $types | ForEach-Object { Write-Host "  $_.FullName" }
    }
    catch [Reflection.ReflectionTypeLoadException] {
        Write-Host "ReflectionTypeLoadException: $($_.Exception.Message)"
        $ex = $_.Exception
        if ($ex.LoaderExceptions) {
            foreach ($le in $ex.LoaderExceptions) {
                Write-Host "LoaderException: $($le.Message)"
                if ($le.InnerException) { Write-Host "  InnerException: $($le.InnerException.Message)" }
            }
        }
    }
}
catch {
    Write-Host "Assembly load failed: $($_.Exception.Message)"
    if ($_.Exception.InnerException) { Write-Host "Inner: $($_.Exception.InnerException.Message)" }
}
