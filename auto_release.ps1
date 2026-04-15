Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

function Write-Step {
    param([string]$Message)
    Write-Host "[auto-release] $Message"
}

function Require-Command {
    param([string]$Name)
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command) {
        throw "Required command not found: $Name"
    }
    return $command
}

function New-RandomSecret {
    param([int]$Length = 16)
    $chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789"
    $bytes = New-Object byte[] $Length
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }

    $builder = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $Length; $i++) {
        [void]$builder.Append($chars[$bytes[$i] % $chars.Length])
    }
    return $builder.ToString()
}

function Load-Secrets {
    param([string]$Path)
    $result = @{}
    if (-not (Test-Path $Path)) {
        return $result
    }

    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line.Length -eq 0 -or $line.StartsWith("#")) {
            return
        }
        if ($line -match "^([^=]+)=(.*)$") {
            $key = $matches[1].Trim()
            $value = $matches[2]
            $result[$key] = $value
        }
    }
    return $result
}

function Save-Secrets {
    param(
        [string]$Path,
        [hashtable]$Secrets
    )

    $primaryOrder = @("STORE_PASSWORD", "KEY_PASSWORD", "KEY_ALIAS", "STORE_FILE")
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($key in $primaryOrder) {
        if ($Secrets.ContainsKey($key) -and -not [string]::IsNullOrWhiteSpace([string]$Secrets[$key])) {
            $lines.Add("$key=$($Secrets[$key])")
        }
    }

    foreach ($entry in ($Secrets.GetEnumerator() | Sort-Object Name)) {
        if ($primaryOrder -contains $entry.Key) {
            continue
        }
        if ([string]::IsNullOrWhiteSpace([string]$entry.Value)) {
            continue
        }
        $lines.Add("$($entry.Key)=$($entry.Value)")
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($Path, $lines, $utf8NoBom)
}

function Ensure-GitIgnoreEntry {
    param(
        [string]$GitignorePath,
        [string]$Entry
    )

    if (-not (Test-Path $GitignorePath)) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($GitignorePath, "$Entry`r`n", $utf8NoBom)
        return
    }

    $lines = Get-Content $GitignorePath
    foreach ($line in $lines) {
        if ($line.Trim() -eq $Entry) {
            return
        }
    }
    Add-Content -Path $GitignorePath -Value $Entry
}

function Read-KeystoreAlias {
    param(
        [string]$KeystorePath,
        [string]$StorePassword
    )

    $previousEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $raw = & keytool -list -keystore $KeystorePath -storepass $StorePassword 2>&1
    } finally {
        $ErrorActionPreference = $previousEap
    }
    if ($LASTEXITCODE -ne 0) {
        return $null
    }
    foreach ($line in $raw) {
        if ($line -match '^\s*Alias name:\s*(.+)$') {
            return $matches[1].Trim()
        }
    }
    foreach ($line in $raw) {
        if ($line -match '^\s*([^,]+)\s*,.*PrivateKeyEntry') {
            return $matches[1].Trim()
        }
    }
    return $null
}

function Relative-Path {
    param(
        [string]$Root,
        [string]$Path
    )

    $rootFull = [System.IO.Path]::GetFullPath($Root)
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    if ($pathFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $pathFull.Substring($rootFull.Length).TrimStart([char[]]@('\', '/'))
        return ($relative -replace "\\", "/")
    }
    throw "Path is not under repository root: $Path"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath($scriptDir)

Push-Location $repoRoot
try {
    Write-Step "Checking required tools"
    $gh = Require-Command "gh"
    Require-Command "git" | Out-Null
    Require-Command "keytool" | Out-Null
    Write-Step "GitHub CLI found at $($gh.Source)"

    Write-Step "Checking GitHub authentication"
    $authed = $true
    try {
        gh auth status | Out-Host
    } catch {
        $authed = $false
    }

    if (-not $authed) {
        $token = $env:GH_TOKEN
        if ([string]::IsNullOrWhiteSpace($token)) {
            $token = $env:GITHUB_TOKEN
        }
        if ([string]::IsNullOrWhiteSpace($token)) {
            throw "gh is not authenticated and neither GH_TOKEN nor GITHUB_TOKEN is set"
        }
        $token | gh auth login --with-token | Out-Host
        gh auth status | Out-Host
    }

    $secretsPath = Join-Path $repoRoot ".signing_secrets"
    $secrets = Load-Secrets -Path $secretsPath
    $secretsCreated = $false
    $secretsUpdated = $false

    if ($secrets.Count -eq 0) {
        Write-Step "Creating .signing_secrets"
        $secrets["STORE_PASSWORD"] = New-RandomSecret -Length 16
        $secrets["KEY_PASSWORD"] = New-RandomSecret -Length 16
        $secretsCreated = $true
        $secretsUpdated = $true
    }

    if (-not $secrets.ContainsKey("STORE_PASSWORD") -or [string]::IsNullOrWhiteSpace([string]$secrets["STORE_PASSWORD"])) {
        throw "STORE_PASSWORD is missing in .signing_secrets"
    }
    if (-not $secrets.ContainsKey("KEY_PASSWORD") -or [string]::IsNullOrWhiteSpace([string]$secrets["KEY_PASSWORD"])) {
        throw "KEY_PASSWORD is missing in .signing_secrets"
    }

    $gitignorePath = Join-Path $repoRoot ".gitignore"
    Ensure-GitIgnoreEntry -GitignorePath $gitignorePath -Entry ".signing_secrets"
    Ensure-GitIgnoreEntry -GitignorePath $gitignorePath -Entry "*.keystore"

    $appKeystorePath = Join-Path $repoRoot "app/release.keystore"
    $rootKeystorePath = Join-Path $repoRoot "release.keystore"
    $keystorePath = $null

    if (Test-Path $appKeystorePath) {
        $keystorePath = $appKeystorePath
    } elseif (Test-Path $rootKeystorePath) {
        $keystorePath = $rootKeystorePath
    } else {
        $keystorePath = $appKeystorePath
        $keyAlias = if ($secrets.ContainsKey("KEY_ALIAS") -and -not [string]::IsNullOrWhiteSpace([string]$secrets["KEY_ALIAS"])) { [string]$secrets["KEY_ALIAS"] } else { "key0" }
        Write-Step "Creating release keystore at $keystorePath"
        & keytool -genkeypair -v `
            -keystore $keystorePath `
            -storepass $secrets["STORE_PASSWORD"] `
            -keypass $secrets["KEY_PASSWORD"] `
            -alias $keyAlias `
            -keyalg RSA `
            -keysize 2048 `
            -validity 36500 `
            -dname "CN=localhost, OU=Unknown, O=Unknown, L=Unknown, S=Unknown, C=US" | Out-Host

        $secrets["KEY_ALIAS"] = $keyAlias
        $secretsUpdated = $true
    }

    $keystoreRelativePath = Relative-Path -Root $repoRoot -Path $keystorePath

    if (-not $secrets.ContainsKey("STORE_FILE") -or [string]::IsNullOrWhiteSpace([string]$secrets["STORE_FILE"])) {
        $secrets["STORE_FILE"] = $keystoreRelativePath
        $secretsUpdated = $true
    }

    if (-not $secrets.ContainsKey("KEY_ALIAS") -or [string]::IsNullOrWhiteSpace([string]$secrets["KEY_ALIAS"])) {
        $detectedAlias = Read-KeystoreAlias -KeystorePath $keystorePath -StorePassword $secrets["STORE_PASSWORD"]
        if ([string]::IsNullOrWhiteSpace($detectedAlias)) {
            throw "Unable to detect key alias from existing keystore"
        }
        $secrets["KEY_ALIAS"] = $detectedAlias
        $secretsUpdated = $true
    }

    if ($secretsUpdated) {
        Save-Secrets -Path $secretsPath -Secrets $secrets
    }

    $buildGradlePath = Join-Path $repoRoot "app/build.gradle"
    if (-not (Test-Path $buildGradlePath)) {
        throw "app/build.gradle not found"
    }

    Write-Step "Bumping version in app/build.gradle"
    $buildGradle = [System.IO.File]::ReadAllText($buildGradlePath)

    $versionCodeMatch = [System.Text.RegularExpressions.Regex]::Match($buildGradle, '(?m)^(\s*versionCode\s+)(\d+)\s*$')
    if (-not $versionCodeMatch.Success) {
        throw "versionCode not found"
    }
    $oldVersionCode = [int]$versionCodeMatch.Groups[2].Value
    $newVersionCode = $oldVersionCode + 1

    $versionNameMatch = [System.Text.RegularExpressions.Regex]::Match($buildGradle, '(?m)^(\s*versionName\s+")([^"]+)("\s*)$')
    if (-not $versionNameMatch.Success) {
        throw "versionName not found"
    }
    $oldVersionName = $versionNameMatch.Groups[2].Value
    $nameParts = $oldVersionName.Split('.')
    if ($nameParts.Length -lt 1 -or -not ($nameParts[$nameParts.Length - 1] -match "^\d+$")) {
        throw "versionName format is not patch-incrementable: $oldVersionName"
    }
    $nameParts[$nameParts.Length - 1] = ([int]$nameParts[$nameParts.Length - 1] + 1).ToString()
    $newVersionName = [string]::Join(".", $nameParts)

    $buildGradle = [System.Text.RegularExpressions.Regex]::new('(?m)^(\s*versionCode\s+)\d+\s*$').Replace(
        $buildGradle,
        "`$1$newVersionCode",
        1
    )
    $buildGradle = [System.Text.RegularExpressions.Regex]::new('(?m)^(\s*versionName\s+")([^"]+)("\s*)$').Replace(
        $buildGradle,
        "`$1$newVersionName`$3",
        1
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($buildGradlePath, $buildGradle, $utf8NoBom)

    Write-Step "Running assembleRelease"
    & .\gradlew.bat assembleRelease --console=plain | Out-Host

    $releaseDir = Join-Path $repoRoot "app/build/outputs/apk/release"
    $apkPath = Join-Path $releaseDir "app-release.apk"
    if (-not (Test-Path $apkPath)) {
        $latestApk = Get-ChildItem -Path $releaseDir -Filter "*.apk" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $latestApk) {
            throw "No release APK found in $releaseDir"
        }
        $apkPath = $latestApk.FullName
    }

    $tagName = "v$newVersionName"
    Write-Step "Committing release changes"
    git add . | Out-Host
    git commit -m "chore: auto-release v$newVersionName" | Out-Host

    $existingTag = (git tag -l $tagName)
    if (-not [string]::IsNullOrWhiteSpace($existingTag)) {
        throw "Tag already exists: $tagName"
    }
    git tag $tagName | Out-Host
    git push origin main --tags | Out-Host

    Write-Step "Creating GitHub Release"
    gh release create $tagName $apkPath --title "Release $tagName" --generate-notes | Out-Host
    $releaseUrl = (gh release view $tagName --json url --jq .url).Trim()

    Write-Host "AUTO_RELEASE_VERSION=$newVersionName"
    Write-Host "AUTO_RELEASE_TAG=$tagName"
    Write-Host "AUTO_RELEASE_APK=$apkPath"
    Write-Host "AUTO_RELEASE_URL=$releaseUrl"
    if ($secretsCreated) {
        Write-Host "AUTO_RELEASE_STORE_PASSWORD=$($secrets['STORE_PASSWORD'])"
        Write-Host "AUTO_RELEASE_KEY_PASSWORD=$($secrets['KEY_PASSWORD'])"
    } else {
        Write-Host "AUTO_RELEASE_PASSWORDS=REUSED"
    }
} finally {
    Pop-Location
}