param(
    [string]$in = ".\model\min-rv.smv",
    [string]$outDir = ".\dist",
    [string]$cmd = ".\trace-bmc.template",
    [int]$tracelen = 10,
    [string[]]$props = @(
        "NO_LEAK",
        "NO_LEAK_SANITIZED",
        "NO_LEAK_SANITIZED_NO_MEM_DECLASSIFICATION",
        "NO_LEAK_SANITIZED_NO_USE_DECLASSIFIED_MEM",
        "NO_INFLUENCE",
        "NO_INFLUENCE_NO_PUBLIC_READS",
        "NO_INFLUENCE_NO_PUBLIC_READS_SANITIZED",
        "NO_INFLUENCE_NO_PUBLIC_READS_SANITIZED_NO_DECLASSIFICATION"
    )
)

# Create temporary files needed in this script
$preprocessedPath = Join-Path $outDir (Split-Path $in -Leaf)
if (!(Test-Path $preprocessedPath)) {
    New-Item $preprocessedPath
}
$preprocessed = Get-Item $preprocessedPath
$trace = New-TemporaryFile
$replaced_cmd = New-TemporaryFile

if (
    ($Null -eq (Get-Content $preprocessed)) -or
    (($preprocessed.LastWriteTime) -lt (Get-Item $in).LastWriteTime)
) {
    # Load command line tools of visual studio as described in
    #  https://stackoverflow.com/a/2124759/7194995
    VsDevCmd.ps1
    # Preprocess the model
    cl.exe /EP /C $in | Out-File -Encoding ascii $preprocessed
}

# Track property time and success
$took_millis = @{}
$succ = @{}
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
    $succ[$prop] = $true
    if ($Null -ne (Get-Content $trace)) {
        $succ[$prop] = $false
        $out = Join-Path $outDir ($prop + ".html")
        # Execute https://github.com/felixlinker/smvtrcviz by script
        smvtrcviz.bat $trace.FullName $out
    }
}

$took_sum = 0
foreach ($prop in $props) {
    $ms = $took_millis[$prop]
    $took_sum += $ms
    $proven = $succ[$prop]
    Write-Host "$prop was proven to be $proven in $ms ms"
}
Write-Host "All proofs took $took_sum ms"

# Clean up temporary files
Remove-Item $trace
Remove-Item $replaced_cmd
