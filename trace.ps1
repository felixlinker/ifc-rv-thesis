param(
    [string]$in = ".\model\min-rv.smv",
    [string]$outDir = ".\dist",
    [string]$cmd = ".\trace-bmc.template",
    [int]$tracelen = 10,
    [switch]$dry = $false,
    [switch]$clean = $false,
    [string[]]$options = @(),
    [string[]]$assumptions = @(
        "SP_BANK",
        "CLEAR_ON_RET",
        "SANITIZE_ON_CALL",
        "NO_PUBLIC_READS",
        "NO_PUBLIC_WRITES",
        "CLEAR_ON_DECLASSIFICATION",
        "CLEAR_CACHE_ON_DECLASSIFICATION",
        "SANITIZE_ON_CLASSIFICATION",
        "SANITIZE_CACHE_ON_CLASSIFICATION"
    ),
    [string[]]$props = @(
        "NO_LEAK",
        "CSR_INTEGRITY",
        "MEMORY_OP_INTEGRITY"
    )
)

# Create temporary files needed in this script
$preprocessedPath = Join-Path $outDir (Split-Path $in -Leaf)
if (!(Test-Path $preprocessedPath)) {
    New-Item $preprocessedPath
}
$preprocessed = Get-Item $preprocessedPath

if (
    $clean -or
    ($Null -eq (Get-Content $preprocessed)) -or
    (($preprocessed.LastWriteTime) -lt (Get-Item $in).LastWriteTime)
) {
    # Preprocess the model
    $expr = ($assumptions + $options | ForEach-Object { "$PSItem=True" }) -join ";"
    expander3.py -s --eval=$expr $header $in `
        | Out-File -Encoding ascii $preprocessed
}

if ($dry) {
    exit
}

$trace = New-TemporaryFile
$replaced_cmd = New-TemporaryFile

# Track property time and success
$took_millis = @{}
$outs = @{}
foreach ($prop in $props) {
    # Replace template-like variables in the command file
    $expr = @(
        "INPUT='$($preprocessed.FullName)'",
        "PROPNAME='$prop'",
        "OUTPUT='$($trace.FullName)'",
        "MAXLEN=$tracelen"
    ) -join ";"
    $expr = $expr.Replace("\", "/")
    expander3.py -s --eval=$expr $cmd | Out-File -encoding ascii $replaced_cmd

    # Clear the trace of any possible previous proof
    Clear-Content $trace
    # Run nuXmv
    $took_millis[$prop] = (Measure-Command {
        nuXmv.exe -source $replaced_cmd.FullName
    }).Milliseconds

    # Map the trace to an html table
    if ($Null -ne (Get-Content $trace)) {
        $out = Join-Path $outDir ($prop + ".html")
        $outs[$prop] = $out
        # Execute https://github.com/felixlinker/smvtrcviz by script
        smvtrcviz.bat $trace.FullName $out
    }
}

$took_sum = 0
foreach ($prop in $props) {
    $ms = $took_millis[$prop]
    $took_sum += $ms
    $proven = ![Bool]$outs[$prop]
    Write-Host "$prop was proven to be $proven in $ms ms"
}
$outs.Values | ForEach-Object { Start-Process $PSItem }
Write-Host "All proofs took $took_sum ms"

# Clean up temporary files
Remove-Item $trace
Remove-Item $replaced_cmd
