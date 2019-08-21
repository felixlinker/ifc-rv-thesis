param(
    [string]$in = ".\model\min-rv.smv",
    [string]$outDir = ".\dist",
    [string]$cmd = ".\trace-bmc.template",
    [int]$tracelen = 10,
    [switch]$dry = $false,
    [switch]$clean = $false,
    [string[]]$options = @(),
    [string[]]$assumptions = @(
        "SP_NO_PUBLIC",
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
$header = New-TemporaryFile

foreach ($symbol in ($assumptions + $options)) {
    Out-File $header -Encoding ascii `
        -InputObject "#define $symbol" `
        -Append
}

if (
    $clean -or
    ($Null -eq (Get-Content $preprocessed)) -or
    (($preprocessed.LastWriteTime) -lt (Get-Item $in).LastWriteTime)
) {
    # Load command line tools of visual studio as described in
    #  https://stackoverflow.com/a/2124759/7194995
    VsDevCmd.ps1
    # Preprocess the model
    cl.exe /EP /C /FI $header $in | Out-File -Encoding ascii $preprocessed
}

Remove-Item $header

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
    $cmds = get-content $cmd
    $cmds = $cmds.Replace("[INPUT]", $preprocessed.FullName)
    $cmds = $cmds.Replace("[PROPNAME]", $prop)
    $cmds = $cmds.Replace("[OUTPUT]", $trace.FullName)
    $cmds = $cmds.Replace("[MAXLEN]", $tracelen)
    $cmds | Out-File -encoding ascii $replaced_cmd

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
