
param(
    [string]$OutDir = "./results",
    [string[]]$Options = @(),
    [int]$TraceLen = 10
)

$assumptions = @(
    "SP_BANK",
    "CLR_ON_RET",
    "SAN_ON_CALL",
    "NO_PUBLIC_READS",
    "NO_PUBLIC_WRITES",
    "CLR_ON_DECLASSIFICATION",
    "CLR_CACHE_ON_DECLASSIFICATION",
    "SAN_ON_CLASSIFICATION",
    "SAN_CACHE_ON_CLASSIFICATION"
)
foreach ($assumption in $assumptions) {
    $out = (Join-Path $OutDir $assumption) -replace "_","-"
    New-Item -ItemType Directory -Path $out -Force
    $localAssumptions = $assumptions | Where-Object { $PSItem -ne $assumption }
    .\trace.ps1 -Cmd "check_ltlspec_bmc -k $TraceLen" -OutDir $out -NoStart `
        -Assumptions $localAssumptions -TeX
}
