
param(
    [string]$OutDir = "./results",
    [string[]]$Options = @(),
    [int]$TraceLen = 10
)

$assumptions = @(
    "SP_BANK",
    "CLEAR_ON_RET",
    "SANITIZE_ON_CALL",
    "NO_PUBLIC_READS",
    "NO_PUBLIC_WRITES",
    "CLEAR_ON_DECLASSIFICATION",
    "CLEAR_CACHE_ON_DECLASSIFICATION",
    "SANITIZE_ON_CLASSIFICATION",
    "SANITIZE_CACHE_ON_CLASSIFICATION"
)
foreach ($assumption in $assumptions) {
    $out = Join-Path $OutDir $assumption
    New-Item -ItemType Directory -Path $out -Force
    $localAssumptions = $assumptions | Where-Object { $PSItem -ne $assumption }
    .\trace.ps1 -Cmd "check_ltlspec_bmc -k $TraceLen" -OutDir $out -NoStart `
        -Assumptions $localAssumptions -TeX
}
