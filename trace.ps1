<#
.SYNOPSIS

Runs proof in nuXmv.

.DESCRIPTION

The trace.ps1 script runs proofs with a list of assumtpions and options. It
attempts to prove each property given. If a property fails, its trace will be
pretty-printed as HTML table.

.PARAMETER In
Path to the .smv model. Model will be preprocessed with expander3.py.
Default: .\model\min-rv.smv


.PARAMETER OutDir
Path where results are placed. These include the preprocessed model and any
counter-example as HTML table. Default: .\dist

.PARAMETER CmdFile
Path to a file that holds commands for nuXmv. Will be preprocessed with
expander3.py. Various other options to this script will be used as variable.
Default: .\trace-bmc.template

.PARAMETER Dry
True to only preprocess the model and not perform any proofs. Default: False

.PARAMETER Cmd
Will replace $CMD in the command file. Default: check_ltlspec_klive

.PARAMETER Options
List of options to be enabled. Default: None.

.PARAMETER Assumptions
Array of assumptions for proofs. Default: All assumptions available.

.PARAMETER Props
List of properties to prove. Default: All properties but SYNTAX_CANARY.

.INPUTS

None.

.OUTPUTS

Miscellaneous logs and a summary how long the proofs took to run.

.EXAMPLE

PS> .\trace.ps1

.EXAMPLE

PS> .\trace.ps1 -cmd "check_ltlspec_bmc -k 10" -options CACHE_VULN

#>

param(
    [string]$In = ".\model\min-rv.smv",
    [string]$OutDir = ".\dist",
    [string]$CmdFile = ".\trace-bmc.template",
    [switch]$Dry = $false,
    [switch]$TeX = $false,
    [switch]$NoStart = $false,
    [string]$Cmd = "check_ltlspec_klive",
    [string[]]$Options = @(),
    [string[]]$Assumptions = @(
        "SP_SAFETY",
        "SP_BANK",
        "CLR_ON_RET",
        "SAN_ON_CALL",
        "NO_PUBLIC_READS",
        "NO_PUBLIC_WRITES",
        "CLR_ON_DECLASSIFICATION",
        "CLR_CACHE_ON_DECLASSIFICATION",
        "SAN_ON_CLASSIFICATION",
        "SAN_CACHE_ON_CLASSIFICATION"
    ),
    [string[]]$IgnoreAssumptions = @(),
    [string[]]$Props = @(
        "NO_LEAK",
        "CSR_INTEGRITY",
        "MEMORY_OP_INTEGRITY"
    )
)

function unixTime() {
    return [double]::Parse((Get-Date -UFormat %s))
}

# Create temporary files needed in this script
$preprocessedPath = Join-Path $OutDir (Split-Path $In -Leaf)
if (!(Test-Path $preprocessedPath)) {
    New-Item $preprocessedPath
}
$preprocessed = Get-Item $preprocessedPath

# Preprocess the model
$localAssumptions = $Assumptions | Where-Object {
    !$IgnoreAssumptions.Contains($PSItem)
}
$expr = ($localAssumptions + $Options `
    | ForEach-Object { "$PSItem=True" }) -join ";"
expander.py -s --eval=$expr $header $In `
    | Out-File -Encoding ascii $preprocessed

if ($Dry) {
    exit
}

$replaced_cmd = New-TemporaryFile

# Track property time and success
$took_seconds = @{}
$outs = @{}
foreach ($prop in $Props) {
    # Replace template-like variables in the command file
    $trace = Join-Path $OutDir ($prop + ".xml")
    if (Test-Path $trace) {
        Remove-Item $trace
    }
    $expr = @(
        "INPUT='$($preprocessed.FullName)'",
        "PROPNAME='$prop'",
        "OUTPUT='$trace'",
        "CMD='$($Cmd)'"
    ) -join ";"
    $expr = $expr.Replace("\", "/")
    expander.py -s --eval=$expr $CmdFile | Out-File -encoding ascii $replaced_cmd

    # Run nuXmv
    $delta = unixTime
    nuXmv.exe -source $replaced_cmd.FullName
    $delta -= unixTime
    $took_seconds[$prop] = [System.Math]::Abs($delta)

    # Map the trace to an html table
    if (Test-Path $trace) {
        $out = Join-Path $OutDir ($prop + ".html")
        $outs[$prop] = $out
        # Execute https://github.com/felixlinker/smvtrcviz by script
        smvtrcviz.ps1 -i $trace | Out-File $out
        if ($TeX) {
            $texName = $prop + ".tex" -replace "_","-"
            smvtrcviz.ps1 -i $trace -m MINRV8 `
                | Out-File -Encoding ascii (Join-Path $OutDir $texName)
        }
    }
}

$took_sum = 0
foreach ($prop in $Props) {
    $s = $took_seconds[$prop]
    $took_sum += $s
    $proven = ![Bool]$outs[$prop]
    Write-Host "$prop was proven to be $proven in $s s"
}
if (!$NoStart) {
    $outs.Values | ForEach-Object { Start-Process $PSItem }
}
Write-Host "All proofs took $took_sum s"

# Clean up temporary files
Remove-Item $replaced_cmd
