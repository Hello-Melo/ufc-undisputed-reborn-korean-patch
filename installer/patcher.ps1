param(
    [ValidateSet('Install','Check','Restore')][string]$Mode='Install',
    [string]$RootPath,[string]$GamePath,[string]$XeniaPath,[string]$BackupPath
)
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.Encoding]::UTF8
trap { Write-Host ('오류: '+$_.Exception.Message) -ForegroundColor Red; exit 1 }
function Read-Json([string]$Path) { return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json) }
function Write-Json([string]$Path,$Value) {
    $text=$Value | ConvertTo-Json -Depth 16
    [IO.File]::WriteAllText($Path,$text,(New-Object Text.UTF8Encoding($false)))
}
function Get-Hash([string]$Path) {
    $f=[IO.File]::OpenRead($Path);$a=[Security.Cryptography.SHA256]::Create()
    try {return [BitConverter]::ToString($a.ComputeHash($f)).Replace('-','').ToLowerInvariant()}
    finally {$a.Dispose();$f.Dispose()}
}
function Current-Hash([string]$Path) {if([IO.File]::Exists($Path)){return (Get-Hash $Path)};return $null}
function Safe-Path([string]$Root,[string]$Relative) {
    $base=[IO.Path]::GetFullPath($Root).TrimEnd('\')
    if([IO.Path]::IsPathRooted($Relative) -or $Relative.Contains(':') -or $Relative -match '(^|[\\/])\.\.?([\\/]|$)'){throw ('허용하지 않는 상대 경로입니다: '+$Relative)}
    $full=[IO.Path]::GetFullPath([IO.Path]::Combine($base,$Relative))
    if(!$full.StartsWith($base+'\',[StringComparison]::OrdinalIgnoreCase)){throw ('선택 폴더 밖의 경로입니다: '+$Relative)}
    $probe=$full
    while($probe.Length -ge $base.Length){
        if((Test-Path -LiteralPath $probe) -and ((Get-Item -LiteralPath $probe -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw ('연결된 폴더는 지원하지 않습니다: '+$probe)}
        if($probe.Length -eq $base.Length){break};$probe=[IO.Path]::GetDirectoryName($probe)
    }
    return $full
}
function Select-Folder([string]$Title) {
    Add-Type -AssemblyName System.Windows.Forms
    $d=New-Object System.Windows.Forms.FolderBrowserDialog;$d.Description=$Title;$d.ShowNewFolderButton=$false
    try {if($d.ShowDialog() -ne 'OK'){throw '폴더 선택을 취소했습니다.'};return $d.SelectedPath}finally{$d.Dispose()}
}
function Ensure-Closed {if(@(Get-Process xenia* -ErrorAction SilentlyContinue).Count){throw 'Xenia를 완전히 종료하고 다시 실행해 주세요.'}}
function Resolve-Roots {
    if(!$RootPath -and (!$GamePath -or !$XeniaPath)){$script:RootPath=Select-Folder 'Reborn 게임과 Xenia가 들어 있는 폴더를 선택하세요.'}
    $bases=@()
    if($RootPath){$bases+=([IO.Path]::GetFullPath($RootPath).TrimEnd('\'))}
    if($GamePath){$script:GamePath=[IO.Path]::GetFullPath($GamePath).TrimEnd('\');$bases+=[IO.Path]::GetDirectoryName($GamePath)}
    if($XeniaPath){$script:XeniaPath=[IO.Path]::GetFullPath($XeniaPath).TrimEnd('\');$bases+=[IO.Path]::GetDirectoryName($XeniaPath)}
    if($RootPath){$bases+=[IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($RootPath).TrimEnd('\'))}
    $candidates=@()
    foreach($b in @($bases | Select-Object -Unique)){
        if(!$b -or !(Test-Path -LiteralPath $b -PathType Container)){continue}
        $candidates+=$b
        $candidates+=@(Get-ChildItem -LiteralPath $b -Directory | Where-Object {!($_.Attributes -band [IO.FileAttributes]::ReparsePoint)} | ForEach-Object {$_.FullName})
    }
    $candidates=@($candidates | Select-Object -Unique)
    if(!$GamePath){
        $games=@($candidates | Where-Object {[IO.File]::Exists((Join-Path $_ 'default.xex'))})
        if($games.Count -eq 1){$script:GamePath=$games[0]}else{$script:GamePath=Select-Folder 'default.xex가 들어 있는 Reborn 1.1 게임 폴더를 선택하세요.'}
    }
    if(!$XeniaPath){
        $emus=@($candidates | Where-Object {[IO.File]::Exists((Join-Path $_ 'xenia_canary.exe')) -or [IO.File]::Exists((Join-Path $_ 'xenia.exe'))})
        if($emus.Count -eq 1){$script:XeniaPath=$emus[0]}else{$script:XeniaPath=Select-Folder '사용하는 Xenia 실행 파일이 들어 있는 폴더를 선택하세요.'}
    }
    $script:GamePath=[IO.Path]::GetFullPath($GamePath).TrimEnd('\');$script:XeniaPath=[IO.Path]::GetFullPath($XeniaPath).TrimEnd('\')
}
function Get-Target($Record) {
    if($Record.Scope -eq 'game'){
        if(!$Record.Path.StartsWith('DAT/',[StringComparison]::Ordinal) -or $Record.Path -match '(?i)(^|/)(sound|motion|chara|save|content)(/|$)'){throw '게임 적용 경로가 허용 범위를 벗어납니다.'}
        return (Safe-Path $GamePath $Record.Path)
    }
    if($Record.Scope -eq 'xenia'){
        if($addonPaths -notcontains $Record.Path){throw '한글패치 보조 파일 밖의 Xenia 경로입니다.'}
        return (Safe-Path $XeniaPath $Record.Path)
    }
    if($Record.Scope -eq 'xenia-config' -and $Record.Path -eq 'config/5451087D.config.toml'){
        return (Safe-Path $XeniaPath $Record.Path)
    }
    throw '알 수 없는 적용 구분입니다.'
}
function Get-Upgrade($File,$Hash) {
    $items=@($File.Previous | Where-Object {$_ -and $_.Hash -eq $Hash})
    if($items.Count -gt 1){throw ('이전 버전 해시 기록이 중복됩니다: '+$File.Path)}
    if($items.Count -eq 1){return $items[0]};return $null
}
function Test-Backup-Transition($File,$Record) {
    if($File.Scope -ne $Record.Scope -or $File.Path -ne $Record.Path){return $false}
    $beforeKnown=($Record.BeforeHash -eq $File.BeforeHash -or $null -ne (Get-Upgrade $File $Record.BeforeHash))
    $afterKnown=($Record.AfterHash -eq $File.AfterHash -or $null -ne (Get-Upgrade $File $Record.AfterHash))
    return ($beforeKnown -and $afterKnown -and $Record.BeforeHash -ne $Record.AfterHash)
}
function Hash-Bytes([byte[]]$Bytes) {
    $a=[Security.Cryptography.SHA256]::Create()
    try {return [BitConverter]::ToString($a.ComputeHash($Bytes)).Replace('-','').ToLowerInvariant()} finally {$a.Dispose()}
}
function Thumbnail-Config([byte[]]$Bytes) {
    $utf8=New-Object Text.UTF8Encoding($false,$true)
    $bom=($Bytes.Length -ge 3 -and $Bytes[0] -eq 239 -and $Bytes[1] -eq 187 -and $Bytes[2] -eq 191)
    $offset=0;if($bom){$offset=3}
    $value=$utf8.GetString($Bytes,$offset,$Bytes.Length-$offset)
    $newline="`n";if($value.Contains("`r`n")){$newline="`r`n"}
    $sections=[regex]::Matches($value,'(?m)^[ \t]*\[([^\]\r\n]+)\][ \t]*(?:#[^\r\n]*)?\r?$')
    $gpu=@($sections | Where-Object {$_.Groups[1].Value -eq 'GPU'})
    if($gpu.Count -gt 1){throw '게임별 설정의 GPU 구역이 중복됩니다.'}
    if($gpu.Count -eq 1){
        $start=$gpu[0].Index+$gpu[0].Length;$end=$value.Length
        foreach($section in $sections){if($section.Index -gt $gpu[0].Index){$end=$section.Index;break}}
        $part=$value.Substring($start,$end-$start)
        $keys=[regex]::Matches($part,'(?m)^[ \t]*readback_resolve[ \t]*=[^\r\n]*')
        if($keys.Count -gt 1){throw '게임별 설정의 readback_resolve가 중복됩니다.'}
        if($keys.Count -eq 1){
            $key=$keys[0]
            $parsed=[regex]::Match($key.Value,'^(?<prefix>[ \t]*readback_resolve[ \t]*=[ \t]*)["''](?<mode>none|fast|full)["''](?<tail>[ \t]*(?:#.*)?)$')
            if(!$parsed.Success){throw '게임별 readback_resolve 값은 none, fast, full 문자열이어야 합니다.'}
            if($parsed.Groups['mode'].Value -eq 'full'){return ,$Bytes}
            $replacement=$parsed.Groups['prefix'].Value+'"full"'+$parsed.Groups['tail'].Value
            $absolute=$start+$key.Index;$value=$value.Substring(0,$absolute)+$replacement+$value.Substring($absolute+$key.Length)
        }else{
            $prefix=$value.Substring(0,$end);if(!$prefix.EndsWith("`n")){$prefix+=$newline}
            $value=$prefix+'readback_resolve = "full"'+$newline+$value.Substring($end)
        }
    }else{
        if($value.Length -and !$value.EndsWith("`n")){$value+=$newline}
        $value+='[GPU]'+$newline+'readback_resolve = "full"'+$newline
    }
    $out=$utf8.GetBytes($value);if($bom){$out=[byte[]](@(239,187,191)+$out)}
    return ,$out
}
function Check-Base {
    if(![IO.File]::Exists((Join-Path $XeniaPath 'xenia_canary.exe')) -and ![IO.File]::Exists((Join-Path $XeniaPath 'xenia.exe'))){throw '선택한 폴더에 Xenia 실행 파일이 없습니다.'}
    if(!(Test-Path -LiteralPath (Join-Path $XeniaPath 'patches') -PathType Container)){throw 'Reborn의 기존 patches 폴더가 없습니다. Reborn 1.1을 먼저 준비해 주세요.'}
    foreach($f in $manifest.BaseFiles){if((Current-Hash (Safe-Path $GamePath $f.Path)) -ne $f.Hash){throw ('지원하는 Reborn 1.1 판본과 다릅니다: '+$f.Path)}}
}
function Atomic-Copy([string]$Source,[string]$Target) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Target)) | Out-Null
    $temp=$Target+'.melo-'+[Guid]::NewGuid().ToString('N')+'.tmp'
    try {[IO.File]::Copy($Source,$temp,$false);[MeloRebornDelta]::Replace($temp,$Target)}
    finally {if([IO.File]::Exists($temp)){[IO.File]::Delete($temp)}}
}
function Commit-Changes($Operations) {
    $done=New-Object Collections.ArrayList
    try {
        foreach($o in $Operations){
            if((Current-Hash $o.Target) -ne $o.BeforeHash){throw ('적용 직전 파일이 달라졌습니다: '+$o.Target)}
            [void]$done.Add($o)
            if($o.AfterHash){Atomic-Copy $o.Staged $o.Target}else{[IO.File]::Delete($o.Target)}
            if((Current-Hash $o.Target) -ne $o.AfterHash){throw ('적용 후 해시가 다릅니다: '+$o.Target)}
        }
    }catch{
        $reason=$_;$failed=$false
        for($i=$done.Count-1;$i -ge 0;$i--){
            $o=$done[$i]
            try {
                if((Current-Hash $o.Target) -ne $o.BeforeHash){if($o.BeforeHash){Atomic-Copy $o.Rollback $o.Target}else{[IO.File]::Delete($o.Target)}}
                if((Current-Hash $o.Target) -ne $o.BeforeHash){throw '되돌린 파일의 해시가 다릅니다.'}
            }catch{$failed=$true;Write-Host ('수동 복구에 사용할 백업: '+$o.Rollback)}
        }
        if($failed){throw ('자동 되돌리기 일부 실패. 백업을 보존해 주세요. 원인: '+$reason.Exception.Message)}
        throw ('이번 변경을 모두 되돌렸습니다. 원인: '+$reason.Exception.Message)
    }
}
$manifest=Read-Json (Join-Path $PSScriptRoot 'manifest.json')
if($manifest.Format -ne 'Melo-Reborn-XOR-1' -or $manifest.Game -ne 'Undisputed Reborn 1.1'){throw 'Reborn 전용 배포 형식이 아닙니다.'}
$configRule=$manifest.Configuration
if(!$configRule -or $configRule.Scope -ne 'xenia-config' -or $configRule.Path -ne 'config/5451087D.config.toml' -or $configRule.Setting -ne 'GPU.readback_resolve' -or $configRule.Value -ne 'full'){throw '이미지 저장용 설정 기록이 올바르지 않습니다.'}
$addonPaths=@('patches/5451087D - Melo Korean Fighter Name Pipeline.patch.toml','patches/5451087D - Melo Korean Font Memory.patch.toml')
foreach($f in $manifest.RuntimeFiles){if((Get-Hash (Safe-Path $PSScriptRoot $f.Path)) -ne $f.Hash){throw ('설치 도구가 손상됐습니다: '+$f.Path)}}
foreach($r in $manifest.Files){
    if((Get-Hash (Safe-Path $PSScriptRoot $r.Delta)) -ne $r.DeltaHash){throw ('패치 차이 자료가 손상됐습니다: '+$r.Delta)}
    foreach($u in @($r.Previous)){if($u -and (Get-Hash (Safe-Path $PSScriptRoot $u.Delta)) -ne $u.DeltaHash){throw ('이전 버전 업데이트 자료가 손상됐습니다: '+$r.Path)}}
}
Add-Type -Path (Safe-Path $PSScriptRoot 'lib/MeloRebornDelta.cs')
if($Mode -ne 'Check'){Ensure-Closed}
if($Mode -eq 'Restore' -and $BackupPath){
    if(Test-Path -LiteralPath $BackupPath -PathType Container){$BackupPath=Join-Path $BackupPath 'backup.json'}
    $b=Read-Json $BackupPath;$script:GamePath=$b.GamePath;$script:XeniaPath=$b.XeniaPath
}else{Resolve-Roots}
Check-Base
if($Mode -eq 'Restore'){
    if(!$BackupPath){
        $backupBase=Safe-Path $GamePath 'Melo_Reborn_KO_Backups'
        $choices=@();$restoredChoices=@()
        if(Test-Path -LiteralPath $backupBase){
            foreach($dir in @(Get-ChildItem -LiteralPath $backupBase -Directory | Sort-Object Name -Descending)){
                $fp=Join-Path $dir.FullName 'backup.json'
                if([IO.File]::Exists($fp)){$candidate=Read-Json $fp;if($candidate.Format -eq 'Melo-Reborn-backup-1'){if($candidate.Status -in @('Installed','Prepared')){$choices+=$fp}elseif($candidate.Status -eq 'Restored'){$restoredChoices+=$fp}}}
            }
        }
        if(!$choices.Count){$choices=@($restoredChoices)}
        if(!$choices.Count){throw '이 설치 도구로 만든 백업이 없습니다. 게임 폴더의 Melo_Reborn_KO_Backups를 확인해 주세요.'}
        $BackupPath=$choices[0]
    }
    $BackupPath=[IO.Path]::GetFullPath($BackupPath);$backupRoot=[IO.Path]::GetDirectoryName($BackupPath);$b=Read-Json $BackupPath
    $allowed=Safe-Path $GamePath 'Melo_Reborn_KO_Backups'
    if(!$backupRoot.StartsWith($allowed+'\',[StringComparison]::OrdinalIgnoreCase) -or $b.Format -ne 'Melo-Reborn-backup-1' -or $b.PackageId -ne $manifest.PackageId -or $b.GamePath -ne $GamePath -or $b.XeniaPath -ne $XeniaPath){throw '선택한 게임의 Reborn 한글패치 백업이 아닙니다.'}
    $ops=@()
    foreach($r in $b.Files){
        $matches=@($manifest.Files | Where-Object {Test-Backup-Transition $_ $r})
        $isConfig=($r.Scope -eq 'xenia-config' -and $r.Path -eq $configRule.Path -and $r.ConfigOverride -eq $true)
        if(!$isConfig -and $matches.Count -ne 1){throw '복원 대상이 배포 기록과 다릅니다.'}
        $target=Get-Target $r;$source=$null
        if($r.BeforeHash){$source=Safe-Path $backupRoot $r.Backup;if((Get-Hash $source) -ne $r.BeforeHash){throw ('백업 파일이 손상됐습니다: '+$r.Path)}}
        if($isConfig){
            [byte[]]$original=@();if($source){$original=[IO.File]::ReadAllBytes($source)}
            [byte[]]$expected=Thumbnail-Config $original
            if((Hash-Bytes $expected) -ne $r.AfterHash){throw '백업의 이미지 설정 변경 기록이 올바르지 않습니다.'}
        }
        $current=Current-Hash $target
        if($current -eq $r.BeforeHash -or (!$isConfig -and $current -eq $matches[0].BeforeHash)){continue}
        if($current -ne $r.AfterHash){throw ('설치 뒤 변경된 파일은 덮어쓰지 않습니다: '+$r.Path)}
        $ops+=[PSCustomObject]@{Target=$target;BeforeHash=$current;AfterHash=$r.BeforeHash;Staged=$source;Rollback=$null}
    }
    if(!$ops.Count){Write-Host '이미 설치 전 상태입니다.';return}
    $undo=Safe-Path $backupRoot ('restore-'+[Guid]::NewGuid().ToString('N'));[IO.Directory]::CreateDirectory($undo) | Out-Null;$i=0
    foreach($o in $ops){if($o.BeforeHash){$o.Rollback=Safe-Path $undo (($i.ToString())+'.bin');[IO.File]::Copy($o.Target,$o.Rollback,$false)};$i++}
    Ensure-Closed;Commit-Changes $ops;$b.Status='Restored';Write-Json $BackupPath $b
    Write-Host '게임 파일·한글패치 보조 파일·이미지 저장용 설정을 설치 전 상태로 복원했습니다.';Write-Host '저장 데이터는 변경하지 않았습니다.';return
}
$checks=@();$already=0
foreach($r in $manifest.Files){
    $target=Get-Target $r;$hash=Current-Hash $target
    if($hash -eq $r.AfterHash){$already++;continue}
    $upgrade=$null
    if($hash -ne $r.BeforeHash){$upgrade=Get-Upgrade $r $hash;if(!$upgrade){throw ('지원하지 않는 파일 상태입니다. 다른 판본이나 다른 수정본은 덮어쓰지 않습니다: '+$r.Path)}}
    if($hash -and ((Get-Item -LiteralPath $target).Attributes -band [IO.FileAttributes]::ReadOnly)){throw ('읽기 전용 파일입니다: '+$r.Path)}
    $checks+=[PSCustomObject]@{Record=$r;Target=$target;SourceHash=$hash;DeltaPath=$(if($upgrade){$upgrade.Delta}else{$r.Delta})}
}
$configTarget=Get-Target $configRule;$configHash=Current-Hash $configTarget
[byte[]]$configBytes=@();if($configHash){$configBytes=[IO.File]::ReadAllBytes($configTarget)}
[byte[]]$newConfig=Thumbnail-Config $configBytes
$newConfigHash=Hash-Bytes $newConfig
if($configHash -ne $newConfigHash){
    if($configHash -and ((Get-Item -LiteralPath $configTarget).Attributes -band [IO.FileAttributes]::ReadOnly)){throw '게임별 이미지 설정 파일이 읽기 전용입니다.'}
    $configRecord=[PSCustomObject]@{Scope=$configRule.Scope;Path=$configRule.Path;AfterHash=$newConfigHash;AfterBytes=$newConfig.Length}
    $checks+=[PSCustomObject]@{Record=$configRecord;Target=$configTarget;SourceHash=$configHash;ConfigBytes=$newConfig;ConfigOverride=$true}
}else{$already++}
Write-Host ("판본 검사 완료: 적용할 파일 {0}개 / 이미 적용된 파일 {1}개" -f $checks.Count,$already)
if($Mode -eq 'Check'){Write-Host '검사만 완료했습니다. 파일은 변경하지 않았습니다.';return}
if(!$checks.Count){Write-Host '이미 같은 한글패치가 적용되어 있습니다. 기존 백업을 유지합니다.';return}
$id=(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[Guid]::NewGuid().ToString('N').Substring(0,8)
$backupRoot=Safe-Path $GamePath ('Melo_Reborn_KO_Backups/'+$id);[IO.Directory]::CreateDirectory($backupRoot) | Out-Null
$ops=@();$saved=@();$i=0
foreach($c in $checks){
    $r=$c.Record;$save=$null;$relative=$null
    if($c.SourceHash){$relative='original/'+$r.Scope+'/'+$r.Path;$save=Safe-Path $backupRoot $relative;[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($save)) | Out-Null;[IO.File]::Copy($c.Target,$save,$false);if((Get-Hash $save) -ne $c.SourceHash){throw ('백업 검증 실패: '+$r.Path)}}
    $staged=Safe-Path $backupRoot ('staged/'+$i+'.bin');[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($staged)) | Out-Null;$i++
    if($c.ConfigOverride){[IO.File]::WriteAllBytes($staged,[byte[]]$c.ConfigBytes)}
    else{[MeloRebornDelta]::Expand($save,(Safe-Path $PSScriptRoot $c.DeltaPath),$staged,[int]$r.AfterBytes)}
    if((Get-Hash $staged) -ne $r.AfterHash){throw ('생성한 패치 파일 검증 실패: '+$r.Path)}
    $ops+=[PSCustomObject]@{Target=$c.Target;Staged=$staged;BeforeHash=$c.SourceHash;AfterHash=$r.AfterHash;Rollback=$save}
    $saved+=[PSCustomObject]@{Scope=$r.Scope;Path=$r.Path;Backup=$relative;BeforeHash=$c.SourceHash;AfterHash=$r.AfterHash;ConfigOverride=[bool]$c.ConfigOverride}
}
$record=[PSCustomObject]@{Format='Melo-Reborn-backup-1';PackageId=$manifest.PackageId;Version=$manifest.Version;GamePath=$GamePath;XeniaPath=$XeniaPath;Status='Prepared';Files=$saved}
$backupJson=Safe-Path $backupRoot 'backup.json';Write-Json $backupJson $record
Ensure-Closed
try {Commit-Changes $ops}
catch {$record.Status='RolledBack';Write-Json $backupJson $record;throw}
$record.Status='Installed';Write-Json $backupJson $record
Write-Host 'Reborn 한국어 패치 설치를 완료했습니다.' -ForegroundColor Green
Write-Host ('백업: '+$backupRoot)
Write-Host '게임별 이미지 저장 옵션만 설정했습니다. 다른 설정과 저장 데이터는 유지합니다. 기존 방법으로 실행하세요.'
