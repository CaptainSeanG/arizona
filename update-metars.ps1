$ErrorActionPreference = 'Stop'

$RepoCandidates = @(
  'D:\Github\arizona',
  'C:\Users\macgy\OneDrive\Hobbies\Projects'
)
$RepoPath = $RepoCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $RepoPath) {
  throw "Could not find a valid repo path. Checked: $($RepoCandidates -join ', ')"
}
$MetarPath = Join-Path $RepoPath 'metars.json'
$TempPath = Join-Path $RepoPath 'metars.json.tmp'
$AirportIds = @(
  'KPHX','KDVT','KSDL','KFFZ','KIWA','KCHD','KGYR','KGEU','KLUF',
  'KTUS','KDUG','KOLS','KPGA','KFLG','KINW','KPRC','KGCN','KSEZ',
  'KSOW','KSAD','KSJN','KIGM','KHII','KIFP','KNYL','KRYN','KCGZ',
  'KRNO','KCXP','KMEV','KRTS','KLOL','KTPH','KHTH','KEKO',
  'KELY','KENV','KLAS','KHND','KVGT','KBVU','KNFL',
  'KSFO','KOAK','KSJC','KHAF','KAPC','KSTS','KSMF','KMHR',
  'KMOD','KFAT','KVIS','KBFL','KSBP','KSBA','KOXR','KCMA',
  'KBUR','KVNY','KLGB','KFUL','KSNA','KONT','KPSP','KTRM',
  'KCRQ','KMYF','KSAN'
)
$Url = "https://aviationweather.gov/api/data/metar?format=json&ids=$($AirportIds -join ',')"
$UserAgent = 'captainseang-arizona-metars/1.0'

Set-Location $RepoPath

try {
  $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -UserAgent $UserAgent -OutFile $TempPath
  if ($response.StatusCode -ne 200) {
    throw "Unexpected HTTP status: $($response.StatusCode)"
  }

  $raw = Get-Content -Raw -Path $TempPath -Encoding UTF8
  $data = $raw | ConvertFrom-Json
  if ($null -eq $data) {
    throw 'API returned empty JSON payload'
  }
  if ($data -isnot [System.Array]) {
    throw 'Expected top-level JSON array'
  }

  Move-Item -LiteralPath $TempPath -Destination $MetarPath -Force

  git config user.name "CaptainSeanG"
  git config user.email "233139008+CaptainSeanG@users.noreply.github.com"
  git add metars.json
  git diff --cached --quiet
  if ($LASTEXITCODE -ne 0) {
    git commit -m "Update metars.json"
    git push
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
