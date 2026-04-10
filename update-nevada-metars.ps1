$ErrorActionPreference = 'Stop'

$RepoPath = 'C:\Users\macgy\OneDrive\Hobbies\Projects'
$MetarPath = Join-Path $RepoPath 'nevada-metars.json'
$TempPath = Join-Path $RepoPath 'nevada-metars.json.tmp'
$AirportIds = @(
  'KRNO','KCXP','KMEV','KRTS','KLOL','KTPH','KHTH','KEKO',
  'KELY','KENV','KLAS','KHND','KVGT','KBVU','KNFL'
)
$Url = "https://aviationweather.gov/api/data/metar?format=json&ids=$($AirportIds -join ',')"
$UserAgent = 'captainseang-nevada-metars/1.0'

Set-Location $RepoPath

try {
  Invoke-WebRequest -UseBasicParsing -Uri $Url -UserAgent $UserAgent -OutFile $TempPath

  if (-not (Test-Path $TempPath)) {
    throw 'Download failed: nevada-metars.json.tmp was not created'
  }

  $raw = Get-Content -Raw -Path $TempPath -Encoding UTF8
  if ([string]::IsNullOrWhiteSpace($raw)) {
    throw 'API returned empty content'
  }

  $data = $raw | ConvertFrom-Json
  if ($null -eq $data) {
    throw 'API returned null JSON payload'
  }
  if ($data -isnot [System.Array]) {
    throw 'Expected top-level JSON array'
  }

  git config user.name "CaptainSeanG"
  git config user.email "233139008+CaptainSeanG@users.noreply.github.com"

  git fetch origin
  git reset --hard origin/main

  Move-Item -LiteralPath $TempPath -Destination $MetarPath -Force

  git add nevada-metars.json
  git diff --cached --quiet
  if ($LASTEXITCODE -ne 0) {
    git commit -m "Update nevada-metars.json"
    git push origin main
  }
  else {
    Write-Host "No changes to commit."
  }
}
catch {
  Write-Error $_
  exit 1
}
finally {
  if (Test-Path $TempPath) {
    Remove-Item -LiteralPath $TempPath -Force
  }
}
