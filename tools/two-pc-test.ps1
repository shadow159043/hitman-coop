param([ValidateSet('Prepare','Launch','Restore')][string]$Mode,[string]$Stage,[string]$TestDir)
$ErrorActionPreference='Stop'
$Retail='C:\Program Files (x86)\Steam\steamapps\common\HITMAN 3\Retail'
$Mods=Join-Path $Retail 'mods'
$Sdk=@('dinput8.dll','ZHMModSDK.dll','ResourceLib_HM3.dll','discord_game_sdk.dll','crashpad_handler.exe')
$Back=Join-Path $TestDir 'backup'
$Manifest=Join-Path $Back 'manifest.csv'
$Control=Join-Path $TestDir 'control'
function Hash([string]$f) {(Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash}
if($Mode -eq 'Prepare'){
 if(Get-Process HITMAN3 -ErrorAction SilentlyContinue){throw 'Game already running'}
 if((Get-Item (Join-Path $Retail 'HITMAN3.exe')).VersionInfo.FileVersion -ne '3.290.1.0'){throw 'Wrong game version'}
 if(Test-Path $Manifest){throw 'Existing backup; restore first'}
 if(-not(Test-Path (Join-Path $Stage 'mods\HitmanCoop.dll'))){throw 'Stage missing'}
 New-Item -ItemType Directory -Force (Join-Path $Back 'sdk'),(Join-Path $Back 'mods') | Out-Null
 $Hashes=@()
 foreach($n in $Sdk){
  $p=Join-Path $Retail $n
  if(Test-Path $p){Copy-Item $p (Join-Path $Back ('sdk\'+$n)) -Force;$Hashes += [pscustomobject]@{Path=$n;Sha=(Hash $p)}}
 }
 foreach($f in (Get-ChildItem -Path $Mods -File -Recurse -Force)){
  $rel=$f.FullName.Substring($Mods.Length+1)
  $dest=Join-Path $Back ('mods\'+$rel)
  New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
  Copy-Item $f.FullName $dest -Force
  $Hashes += [pscustomobject]@{Path=('mods\'+$rel);Sha=(Hash $f.FullName)}
 }
 $Hashes | Export-Csv $Manifest -NoTypeInformation
 'BACKUP_COMPLETE' | Set-Content (Join-Path $Back 'READY')
 try {
  foreach($n in $Sdk){$p=Join-Path $Stage $n;if(-not(Test-Path $p)){throw "Missing SDK file $n"};Copy-Item $p (Join-Path $Retail $n) -Force}
  Get-ChildItem $Mods -Filter '*.dll' -File | Where-Object {$_.Name -match '^(AssassinRivals|Editor)'} | Remove-Item -Force
  Copy-Item (Join-Path $Stage 'mods\HitmanCoop.dll') (Join-Path $Mods 'HitmanCoop.dll') -Force
  $ini=Join-Path $Mods 'hitmancoop.ini'
  $txt=Get-Content $ini -Raw
  $txt=[regex]::Replace($txt,'(?m)^\s*test_control\s*=.*(?:\r?\n|$)','')
  if($txt -notmatch '(?m)^\[general\]'){throw 'No [general] section'}
  $replacement='[general]'+[Environment]::NewLine+'test_control = '+$Control+[Environment]::NewLine
  $txt=[regex]::Replace($txt,'(?m)^\[general\]\s*\r?\n',$replacement,1)
  Set-Content $ini $txt -Encoding UTF8
  Write-Output ('PREPARED '+$env:COMPUTERNAME+' control='+$Control)
 }catch{Write-Output ('PREPARE_ERROR '+$_.Exception.Message+'; run Restore');throw}
}
elseif($Mode -eq 'Launch'){
 if(-not(Test-Path $Manifest)){throw 'Not prepared'}
 if(Get-Process HITMAN3 -ErrorAction SilentlyContinue){throw 'Game already running'}
 Start-Process 'C:\Program Files (x86)\Steam\steam.exe' -ArgumentList '-applaunch','1659040'
 'STEAM_LAUNCH_REQUESTED'
}
elseif($Mode -eq 'Restore'){
 if(-not(Test-Path $Manifest)){throw 'Missing manifest; refusing'}
 Get-Process HITMAN3 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
 Start-Sleep -Seconds 3
 $logs=Join-Path $TestDir 'test-logs'
 New-Item -ItemType Directory -Force $logs | Out-Null
 foreach($n in @('ZHMModLoader.log','ZHMModSDK.log')){
  $p=Join-Path $Retail $n;if(Test-Path $p){Copy-Item $p (Join-Path $logs $n) -Force}
 }
 foreach($n in @('HitmanCoop.log','HitmanCoop-previous.log','HitmanCoop-crash.txt')){
  $p=Join-Path $Mods $n;if(Test-Path $p){Copy-Item $p (Join-Path $logs $n) -Force}
 }
 foreach($suffix in @('.status','.trace')){
  $p=$Control+$suffix;if(Test-Path $p){Copy-Item $p (Join-Path $logs ('control'+$suffix)) -Force}
 }
 foreach($n in $Sdk){
  $src=Join-Path $Back ('sdk\'+$n);$dst=Join-Path $Retail $n
  if(Test-Path $src){Copy-Item $src $dst -Force}elseif(Test-Path $dst){Remove-Item $dst -Force}
 }
 Remove-Item -LiteralPath $Mods -Recurse -Force
 New-Item -ItemType Directory -Force $Mods | Out-Null
 Copy-Item -Path (Join-Path $Back 'mods\*') -Destination $Mods -Force -Recurse
 $issues=@()
 foreach($e in (Import-Csv $Manifest)){
  $dst=Join-Path $Retail $e.Path
  if(-not(Test-Path $dst)){$issues += $e.Path}
  elseif((Hash $dst) -ne $e.Sha){$issues += ($e.Path+' hash mismatch')}
 }
 if($issues.Count){throw ('Rollback verify FAILED: '+($issues -join ';'))}
 'VERIFIED' | Set-Content (Join-Path $TestDir 'RESTORED')
 Write-Output ('RESTORED_SHA_VERIFIED '+$env:COMPUTERNAME)
}