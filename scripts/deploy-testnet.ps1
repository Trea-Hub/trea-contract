param(
    [string] $SourceAccount = $env:STELLAR_SOURCE_ACCOUNT,
    [switch] $SaveContractId,
    [string] $ContractIdFile
)

$ErrorActionPreference = "Stop"

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$wasmPath = Join-Path $repositoryRoot "target\wasm32v1-none\release\registration.wasm"

if ([string]::IsNullOrWhiteSpace($SourceAccount)) {
    throw "Provide -SourceAccount or set STELLAR_SOURCE_ACCOUNT to a configured Stellar identity."
}

if ($SaveContractId -and [string]::IsNullOrWhiteSpace($ContractIdFile)) {
    $ContractIdFile = Join-Path $repositoryRoot ".stellar\registration-testnet-contract-id"
}

Push-Location $repositoryRoot
try {
    & stellar contract build `
        --manifest-path (Join-Path $repositoryRoot "contracts\registration\Cargo.toml") `
        --package registration
    if ($LASTEXITCODE -ne 0) {
        throw "Stellar contract build failed (exit code $LASTEXITCODE)."
    }

    if (-not (Test-Path -LiteralPath $wasmPath)) {
        throw "The contract build did not produce the expected WASM file: $wasmPath"
    }

    $deploymentOutput = & stellar contract deploy `
        --wasm $wasmPath `
        --source-account $SourceAccount `
        --network testnet 2>&1
    $deploymentExitCode = $LASTEXITCODE
    $deploymentOutput | ForEach-Object { Write-Host $_ }
    if ($deploymentExitCode -ne 0) {
        throw "Testnet deployment failed (exit code $deploymentExitCode)."
    }

    $deploymentText = $deploymentOutput | Out-String
    $contractIds = @([regex]::Matches($deploymentText, '\bC[A-Z2-7]{55}\b') |
        ForEach-Object { $_.Value } |
        Sort-Object -Unique)
    if ($contractIds.Count -ne 1) {
        throw "Could not identify exactly one deployed contract ID in the Stellar CLI output."
    }

    $contractId = $contractIds[0]
    Write-Host "Deployed contract ID: $contractId"

    if ($SaveContractId) {
        if ([System.IO.Path]::IsPathRooted($ContractIdFile)) {
            $resolvedFile = [System.IO.Path]::GetFullPath($ContractIdFile)
        }
        else {
            $resolvedFile = [System.IO.Path]::GetFullPath(
                (Join-Path $repositoryRoot $ContractIdFile)
            )
        }
        $parentDirectory = Split-Path -Parent $resolvedFile
        if (-not (Test-Path -LiteralPath $parentDirectory)) {
            New-Item -ItemType Directory -Path $parentDirectory -Force | Out-Null
        }
        Set-Content -LiteralPath $resolvedFile -Value $contractId -NoNewline
        Write-Host "Contract ID saved to: $resolvedFile"
    }
}
finally {
    Pop-Location
}
