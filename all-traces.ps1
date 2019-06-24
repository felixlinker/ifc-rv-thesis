param(
    [string]$in = ".\model\min-rv.smv",
    [string]$outDir = ".\dist",
    [string]$cmd = ".\trace-bmc.template",
    [int]$tracelen = 10
)

foreach($prop in @(
    "NO_LEAK",
    "NO_LEAK_SANITIZED",
    "NO_LEAK_SANITIZED_NO_MEM_DECLASSIFICATION",
    "NO_LEAK_SANITIZED_NO_USE_DECLASSIFIED_MEM",
    "NO_INFLUENCE",
    "NO_INFLUENCE_NO_PUBLIC_READS",
    "NO_INFLUENCE_NO_PUBLIC_READS_SANITIZED"
)) {
    $out = Join-Path $outDir ($prop + ".html")
    .\trace.ps1 -in $in -out $out -prop $prop -cmd $cmd -tracelen $tracelen
}
