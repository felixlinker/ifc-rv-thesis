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
        "NO_INFLUENCE_NO_PUBLIC_READS_SANITIZED"
    )
)

# Create temporary files needed in this script
$preprocessed = New-TemporaryFile
$trace = New-TemporaryFile
$replaced_cmd = New-TemporaryFile

# Preprocess the model with the WSL c-preprocessor
wsl /bin/bash -c "cpp $in".replace("\", "/") `
    | Out-File -Encoding ascii $preprocessed.FullName

foreach ($prop in $props) {
    # Replace template-like variables in the command file
    $cmds = get-content $cmd
    $cmds = $cmds.Replace("[INPUT]", $preprocessed.FullName)
    $cmds = $cmds.Replace("[PROPNAME]", $prop)
    $cmds = $cmds.Replace("[OUTPUT]", $trace.FullName)
    $cmds = $cmds.Replace("[MAXLEN]", $tracelen)
    $cmds | Out-File -encoding ascii $replaced_cmd.FullName

    # Run nuXmv
    nuXmv.exe -source $replaced_cmd.FullName

    # Map the trace to an html table
    if ($Null -ne (Get-Content $trace.FullName)) {
        $out = Join-Path $outDir ($prop + ".html")
        smvtrcviz.bat $trace.FullName $out
    }
}

# Clean up temporary files
Remove-Item -Path $preprocessed
Remove-Item -Path $trace
Remove-Item -Path $replaced_cmd
