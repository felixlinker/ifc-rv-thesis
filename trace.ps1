param(
    [string]$in = ".\model\min-rv.smv",
    [string]$out = ".\dist\trace.html",
    [string]$cmd = ".\trace-bmc.template",
    [int]$tracelen = 10,
    [Parameter(Mandatory=$True)]
    [string]$prop
)

# Create temporary files needed in this script
$preprocessed = New-TemporaryFile
$trace = New-TemporaryFile
$replaced_cmd = New-TemporaryFile

# Preprocess the model with the WSL c-preprocessor
bash -c "cpp $in".replace("\", "/") `
    | Out-File -Encoding ascii $preprocessed.FullName

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
smvtrcviz.bat $trace.FullName $out

# Clean up temporary files
Remove-Item -Path $preprocessed
Remove-Item -Path $trace
Remove-Item -Path $replaced_cmd
