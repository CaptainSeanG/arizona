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
  'KUKI','KRDD','KACV','KCEC',
  'KMOD','KFAT','KVIS','KBFL','KSBP','KSBA','KOXR','KCMA',
  'KBUR','KVNY','KLAX','KLGB','KFUL','KSNA','KONT','KPSP','KTRM',
  'KCRQ','KMYF','KSAN',
  'KASE','KCOS','KBJC','KAPA','KDEN','KDRO','KEGE','KFNL','KGJT','KGUC','KHDN','KMTJ','KPUB',
  'KABQ','KAEG','KALM','KCNM','KDMN','KFMN','KHOB','KLRU','KLVS','KRTN','KROW','KSAF',
  'KOGD','KPVU','KSGU','KCDC','KVEL','KLGU','KHCR','KCNY','KMLF','KBCE','KENV',
  'KBOI','KSUN','KIDA','KPIH','KLWS','KTWF','KMYL','KCOE',
  'KCYS','KCOD','KCPR','KJAC','KLAR','KRKS','KRIW','KSHR','KEVW',
  'KBIL','KMSO','KGPI','KHLN','KBZN','KGTF','KBTM','KDLN','KMLS','KSDY',
  'KICT','KMHK','KFOE','KHUT','KSLN','KDDC','KGCK','KLBL','KCNU','KIXD',
  'KOMA','KLNK','KGRI','KEAR','KBFF','KOFK','KHSI','KLBF','KANW','KBIE',
  'KBIS','KFAR','KGFK','KMOT','KJMS','KXWA','KDIK','KDVL','KGAF','KHEI',
  'KFSD','KRAP','KPIR','KHON','KATY','KYKN','KMBG','KBKX','KICR','KABR',
  'KMSP','KRST','KDLH','KSTC','KBRD','KHIB','KINL','KBJI','KAXN','KMKT',
  'KDSM','KCID','KDBQ','KSUX','KALO','KMCW','KBRL','KOTM','KFOD','KSPW',
  'KSTL','KMCI','KSGF','KCOU','KJLN','KCGI','KIRK','KVIH','KSUS','KSTJ',
  'KLIT','KXNA','KFSM','KTXK','KELD','KJBR','KHOT','KHRO','KPBF','KBPK',
  'KMSY','KBTR','KLFT','KSHV','KAEX','KLCH','KMLU','KNEW','KESF','KARA',
  'KJAN','KGPT','KPIB','KGTR','KMEI','KHBG','KTUP','KGLH','KGWO','KOLV',
  'KBHM','KHSV','KMOB','KMGM','KDHN','KMSL','KTOI','KGAD','KANB','KAUO',
  'KOKC','KTUL','KLAW','KSWO','KADM','KPNC','KMLC','KEND',
  'KEUG','KMFR','KRDM','KOTH','KAST','KHIO','KSLE',
  'KBFI','KOLM','KYKM','KPWT','KPSC','KPUW','KBLI','KPAE',
  'PANC','KHNL','KATL','KBHM','KBOS','KBDL','KDEN','KDCA',
  'KIAD','KBWI','KMIA','KMCO','KTPA','KJAX','KPBI','KCLT',
  'KGSO','KGSP','KORD','KMDW','KIND','KDSM','KMCI','KSDF',
  'KMSY','KBTV','KDTW','KMSP','KSTL','KJFK','KLGA','KEWR',
  'KBUF','KROC','KSYR','KRDU','KCLE','KCMH','KCVG','KOKC',
  'KTUL','KPDX','KPHL','KPIT','KPVD','KCHS','KMYR','KBNA',
  'KMEM','KAUS','KDFW','KDAL','KHOU','KIAH','KSAT','KELP',
  'KCRP','KMAF','KLBB','KABI','KAMA','KBRO','KHRL','KMFE','KSPS','KACT','KCLL',
  'KSLC','KORF','KRIC','KSEA','KGEG',
  'KMKE','KABQ'
) | Select-Object -Unique
$Url = "https://aviationweather.gov/api/data/metar?format=json&ids=$($AirportIds -join ',')"
$UserAgent = 'captainseang-arizona-metars/1.0'

Set-Location $RepoPath

try {
  Invoke-WebRequest -UseBasicParsing -Uri $Url -UserAgent $UserAgent -OutFile $TempPath

  if (-not (Test-Path $TempPath)) {
    throw 'Download failed: metars.json.tmp was not created'
  }

  $raw = Get-Content -Raw -Path $TempPath -Encoding UTF8
  if ([string]::IsNullOrWhiteSpace($raw)) {
    throw 'API returned empty content'
  }
  $data = $raw | ConvertFrom-Json
  if ($null -eq $data) {
    throw 'API returned empty JSON payload'
  }
  if ($data -isnot [System.Array]) {
    throw 'Expected top-level JSON array'
  }

  git config user.name "CaptainSeanG"
  git config user.email "233139008+CaptainSeanG@users.noreply.github.com"

  git fetch origin
  git reset --hard origin/main

  Move-Item -LiteralPath $TempPath -Destination $MetarPath -Force

  git add metars.json
  git diff --cached --quiet
  if ($LASTEXITCODE -ne 0) {
    git commit -m "Update metars.json"
    git push origin main
  }
  else {
    Write-Host "No changes to commit."
  }
}
catch {
  Write-Error ("Update-metars failed: " + $_.Exception.Message)
  exit 1
}
finally {
  if (Test-Path $TempPath) {
    Remove-Item -LiteralPath $TempPath -Force
  }
}
