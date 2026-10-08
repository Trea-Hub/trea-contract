$ErrorActionPreference = "Stop"

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$runId = [Guid]::NewGuid().ToString("N").Substring(0, 8)
$organizer = "trea-demo-organizer-$runId"
$attendeeOne = "trea-demo-attendee-one-$runId"
$attendeeTwo = "trea-demo-attendee-two-$runId"
$wasmPath = Join-Path $repositoryRoot "target\wasm32v1-none\release\registration.wasm"

function Invoke-Stellar {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,
        [switch] $Quiet
    )

    $output = & stellar @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Stellar CLI command failed (exit code $exitCode): stellar $($Arguments -join ' ')"
    }

    if (-not $Quiet -and $null -ne $output) {
        $output | ForEach-Object { Write-Host $_ }
    }

    return @($output | ForEach-Object { "$_" })
}

function Get-AddressFromOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Output,
        [Parameter(Mandatory = $true)]
        [string] $AddressType,
        [Parameter(Mandatory = $true)]
        [string] $Description
    )

    $addressMatches = @([regex]::Matches(($Output -join "`n"), "\b$AddressType[A-Z2-7]{55}\b") |
        ForEach-Object { $_.Value } |
        Sort-Object -Unique)
    if ($addressMatches.Count -ne 1) {
        throw "Could not identify exactly one $Description in the Stellar CLI output."
    }
    return $addressMatches[0]
}

if (-not (Get-Command stellar -ErrorAction SilentlyContinue)) {
    throw "Stellar CLI was not found. Install it before running this Testnet demo."
}

Push-Location $repositoryRoot
try {
    foreach ($identity in @($organizer, $attendeeOne, $attendeeTwo)) {
        Invoke-Stellar -Arguments @(
            "keys", "generate", $identity, "--fund", "--network", "testnet"
        ) -Quiet | Out-Null
    }

    Invoke-Stellar @(
        "contract", "build",
        "--manifest-path", (Join-Path $repositoryRoot "contracts\registration\Cargo.toml"),
        "--package", "registration"
    ) | Out-Null

    if (-not (Test-Path -LiteralPath $wasmPath)) {
        throw "The contract build did not produce the expected WASM file: $wasmPath"
    }

    $organizerAddress = Get-AddressFromOutput `
        -Output (Invoke-Stellar -Arguments @("keys", "address", $organizer) -Quiet) `
        -AddressType "G" `
        -Description "organizer address"
    $attendeeOneAddress = Get-AddressFromOutput `
        -Output (Invoke-Stellar -Arguments @("keys", "address", $attendeeOne) -Quiet) `
        -AddressType "G" `
        -Description "first attendee address"
    $attendeeTwoAddress = Get-AddressFromOutput `
        -Output (Invoke-Stellar -Arguments @("keys", "address", $attendeeTwo) -Quiet) `
        -AddressType "G" `
        -Description "second attendee address"

    $tokenOutput = Invoke-Stellar @(
        "contract", "asset", "deploy",
        "--asset", "native",
        "--source-account", $organizer,
        "--network", "testnet"
    )
    $tokenId = Get-AddressFromOutput `
        -Output $tokenOutput `
        -AddressType "C" `
        -Description "native asset contract ID"

    $contractOutput = Invoke-Stellar @(
        "contract", "deploy",
        "--wasm", $wasmPath,
        "--source-account", $organizer,
        "--network", "testnet"
    )
    $contractId = Get-AddressFromOutput `
        -Output $contractOutput `
        -AddressType "C" `
        -Description "registration contract ID"

    $tokenPrices = "{`"$tokenId`":10000000}"
    Invoke-Stellar @(
        "contract", "invoke",
        "--id", $contractId,
        "--source-account", $organizer,
        "--network", "testnet",
        "--",
        "create_event",
        "--organizer", $organizerAddress,
        "--event-id", "1",
        "--token-prices", $tokenPrices,
        "--capacity", "10",
        "--self-refund-allowed", "true",
        "--refund-deadline", "0"
    ) | Out-Null

    foreach ($attendeeAddress in @($attendeeOneAddress, $attendeeTwoAddress)) {
        $sourceAccount = if ($attendeeAddress -eq $attendeeOneAddress) {
            $attendeeOne
        }
        else {
            $attendeeTwo
        }
        Invoke-Stellar @(
            "contract", "invoke",
            "--id", $contractId,
            "--source-account", $sourceAccount,
            "--network", "testnet",
            "--",
            "register",
            "--attendee", $attendeeAddress,
            "--event-id", "1",
            "--payment-token", $tokenId
        ) | Out-Null
    }

    Write-Host ""
    Write-Host "Testnet demo setup succeeded."
    Write-Host "Network: Testnet"
    Write-Host "Registration contract ID: $contractId"
    Write-Host "Native asset contract ID: $tokenId"
    Write-Host "Event ID: 1 (10 tickets, 1 XLM per registration)"
    Write-Host "Organizer: $organizer ($organizerAddress)"
    Write-Host "Attendee 1: $attendeeOne ($attendeeOneAddress)"
    Write-Host "Attendee 2: $attendeeTwo ($attendeeTwoAddress)"
}
finally {
    Pop-Location
}
