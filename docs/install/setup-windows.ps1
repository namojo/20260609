<#
  Harness 교육 환경 — 자동 점검 / 설치 스크립트 (Windows 전용)

  설치가이드(공통 준비 · Windows)의 1~7단계를 자동으로 점검하고, 빠진 것만 설치합니다.
  문서: https://namojo.github.io/harness-edu/install/setup-windows.html
  이미 설치된 항목은 건드리지 않으므로 여러 번 실행해도 안전합니다.

  사용법 (PowerShell 창에서 스크립트가 있는 폴더로 이동한 뒤):
    .\setup-windows.ps1
    .\setup-windows.ps1 -Codex
    .\setup-windows.ps1 -VerifyOnly

  옵션:
    -Codex        (선택) OpenAI Codex CLI 도 함께 설치. ChatGPT Plus 이상 구독 필요.
    -VerifyOnly   설치하지 않고 현재 상태만 점검.
    -Force        이미 설치된 항목도 다시 설치.
    -SkipLoginCheck  Claude 로그인 실측 점검을 생략 (사용량을 아주 조금 쓰는 검사).

  관리자 권한은 필요하지 않습니다.
#>
param(
    [switch]$Codex,
    [switch]$VerifyOnly,
    [switch]$Force,
    [switch]$SkipLoginCheck
)

$ErrorActionPreference = 'Continue'
try { $OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

# ── 상태 기록 ────────────────────────────────────────────────────────────────
$Result = [ordered]@{
    'Git'                 = '미확인'
    'Claude Code'         = '미확인'
    'Claude 로그인'       = '미확인'
    'Agent Teams'         = '미확인'
    'harness 플러그인'    = '미확인'
    '실습 폴더'           = '미확인'
}
if ($Codex) { $Result['Codex CLI'] = '미확인'; $Result['Codex 로그인'] = '미확인' }
$Problems = [System.Collections.Generic.List[string]]::new()

# ── 출력 헬퍼 ────────────────────────────────────────────────────────────────
$TOTAL = if ($Codex) { 7 } else { 6 }

function Section($num, $label) {
    $pct    = [int][math]::Round($num * 100 / $TOTAL)
    $width  = 20
    $filled = [int][math]::Round($width * $pct / 100)
    if ($filled -lt 0)      { $filled = 0 }
    if ($filled -gt $width) { $filled = $width }
    $bar    = ('#' * $filled) + ('.' * ($width - $filled))
    Write-Host ""
    Write-Host ("[{0}/{1}] {2,-24} [{3}] {4,3}%" -f $num, $TOTAL, $label, $bar, $pct) -ForegroundColor Cyan
}
function Ok($m)   { Write-Host "  [OK]   $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [!]    $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "  [FAIL] $m" -ForegroundColor Red }
function Info($m) { Write-Host "         $m" -ForegroundColor DarkGray }
function Step($m) { Write-Host "  [..]   $m" -ForegroundColor Cyan }

function Installed($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

function RefreshEnv {
    $machine = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    $env:PATH = ($machine, $user, "$env:USERPROFILE\.local\bin") -join ';'
}

# ── 로그 ─────────────────────────────────────────────────────────────────────
$LogDir  = Join-Path $env:USERPROFILE 'harness-setup-logs'
$LogFile = Join-Path $LogDir ("setup-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$transcript = $false
try { Start-Transcript -Path $LogFile -Append -ErrorAction Stop | Out-Null; $transcript = $true } catch { }

try {

# ── 헤더 ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host "   Harness 교육 환경 점검 / 설치 (Windows)" -ForegroundColor Cyan
Write-Host "  ==========================================" -ForegroundColor Cyan
if ($VerifyOnly) { Write-Host "   모드: 점검만 (설치하지 않음)" -ForegroundColor Yellow }
if ($Force)      { Write-Host "   모드: 강제 재설치" -ForegroundColor Yellow }
if ($Codex)      { Write-Host "   선택: Codex CLI 포함" -ForegroundColor Yellow }
Write-Host ""

# ── 사전 점검 ────────────────────────────────────────────────────────────────
Step "사전 점검 중..."
try {
    $null = Invoke-WebRequest -Uri 'https://claude.ai' -UseBasicParsing -TimeoutSec 15 -Method Head -ErrorAction Stop
    Ok "인터넷 연결 정상"
} catch {
    Warn "claude.ai 에 접속할 수 없습니다. 사내 방화벽/VPN 을 확인하세요."
    Info $_.Exception.Message
}

$sysDrive = ($env:SystemDrive).TrimEnd(':')
$free = (Get-PSDrive -Name $sysDrive -ErrorAction SilentlyContinue).Free
if ($free) {
    if ($free -lt 2GB) {
        Fail ("디스크 여유 공간 부족: {0:N1} GB (2 GB 이상 필요)" -f ($free / 1GB))
        $Problems.Add('디스크 여유 공간 2GB 미만')
    } else {
        Ok ("디스크 여유 공간: {0:N1} GB" -f ($free / 1GB))
    }
}

$build = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).CurrentBuild
if ($build) {
    if ([int]$build -lt 17763) {
        Fail "Windows 10 1809(빌드 17763) 이상이 필요합니다. 현재 빌드: $build"
        $Problems.Add('지원되지 않는 Windows 버전')
    } elseif ([int]$build -lt 22000) {
        Ok "Windows 10 (빌드 $build) — 지원됨"
    } else {
        Ok "Windows 11 (빌드 $build)"
    }
}
Info "PowerShell $($PSVersionTable.PSVersion)"

RefreshEnv

# ── 1. Git ───────────────────────────────────────────────────────────────────
Section 1 "Git"
if ((Installed git) -and (-not $Force)) {
    Ok "$(git --version)"
    $Result['Git'] = '설치됨'
} elseif ($VerifyOnly) {
    Fail "git 이 설치되지 않았습니다."
    Info "harness 플러그인을 내려받는 데 필요합니다."
    $Result['Git'] = '없음'
    $Problems.Add('Git 미설치')
} else {
    if (Installed winget) {
        Step "winget 으로 Git 설치 중... (수 분 소요)"
        winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements
        RefreshEnv
        # winget 설치 직후 PATH 반영이 늦는 경우가 있어 기본 설치 경로도 확인한다.
        if (-not (Installed git)) {
            $gitCmd = Join-Path $env:ProgramFiles 'Git\cmd'
            if (Test-Path (Join-Path $gitCmd 'git.exe')) { $env:PATH = "$env:PATH;$gitCmd" }
        }
        if (Installed git) {
            Ok "$(git --version) 설치 완료"
            $Result['Git'] = '설치됨'
        } else {
            Fail "Git 설치를 확인할 수 없습니다. 터미널을 새로 열고 'git --version' 을 확인하세요."
            $Result['Git'] = '확인 필요'
            $Problems.Add('Git 설치 확인 필요')
        }
    } else {
        Fail "winget 을 사용할 수 없어 Git 을 자동 설치할 수 없습니다."
        Info "https://git-scm.com/downloads/win 에서 직접 설치한 뒤 이 스크립트를 다시 실행하세요."
        $Result['Git'] = '수동 설치 필요'
        $Problems.Add('Git 수동 설치 필요')
    }
}

# ── 2. Claude Code ───────────────────────────────────────────────────────────
Section 2 "Claude Code"
if ((Installed claude) -and (-not $Force)) {
    Ok "claude $((claude --version 2>&1 | Select-Object -First 1))"
    $Result['Claude Code'] = '설치됨'
} elseif ($VerifyOnly) {
    Fail "claude 명령어를 찾을 수 없습니다."
    $Result['Claude Code'] = '없음'
    $Problems.Add('Claude Code 미설치')
} else {
    Step "Claude Code 설치 중... (수 분 소요)"
    try {
        Invoke-Expression (Invoke-RestMethod -Uri 'https://claude.ai/install.ps1')
    } catch {
        Fail "설치 스크립트 실행 실패: $($_.Exception.Message)"
    }
    RefreshEnv
    if (Installed claude) {
        Ok "claude $((claude --version 2>&1 | Select-Object -First 1)) 설치 완료"
        $Result['Claude Code'] = '설치됨'
    } else {
        Fail "claude 명령어를 찾을 수 없습니다. 터미널을 닫고 새로 열어 'claude --version' 을 확인하세요."
        $Result['Claude Code'] = '확인 필요'
        $Problems.Add('Claude Code 설치 확인 필요 (터미널 재시작)')
    }
}

# ── 3. Claude 로그인 확인 ────────────────────────────────────────────────────
Section 3 "Claude 로그인"
if (-not (Installed claude)) {
    Warn "Claude Code 가 없어 로그인 확인을 건너뜁니다."
    $Result['Claude 로그인'] = '건너뜀'
} elseif ($SkipLoginCheck) {
    Warn "로그인 확인을 건너뜁니다 (-SkipLoginCheck)."
    Info "직접 확인: claude 실행 → 대화가 되면 정상"
    $Result['Claude 로그인'] = '건너뜀'
} else {
    Step "로그인 상태 확인 중... (최대 90초, 사용량을 아주 조금 씁니다)"
    $job = Start-Job -ScriptBlock { claude -p "reply with exactly: OK" 2>&1 }
    $done = Wait-Job $job -Timeout 90
    $out  = if ($done) { (Receive-Job $job) -join "`n" } else { '' }
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    if ($out -match 'OK') {
        Ok "로그인 확인 완료 (Claude 응답 정상)"
        $Result['Claude 로그인'] = '완료'
    } else {
        Warn "로그인 상태를 확인하지 못했습니다."
        Info "터미널에서 'claude' 를 실행해 브라우저 로그인을 완료하세요 (Pro/Max 구독 계정)."
        if ($out) { Info ("응답: " + ($out -split "`n" | Select-Object -First 2 | Out-String).Trim()) }
        $Result['Claude 로그인'] = '확인 필요'
        $Problems.Add('Claude 로그인 필요 — 터미널에서 claude 실행')
    }
}

# ── 4. Agent Teams 활성화 ───────────────────────────────────────────────────
Section 4 "Agent Teams"
$userVal = [System.Environment]::GetEnvironmentVariable('CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS', 'User')
if ($userVal -eq '1' -and -not $Force) {
    Ok "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 (사용자 환경변수)"
    $env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
    $Result['Agent Teams'] = '활성'
} elseif ($VerifyOnly) {
    Fail "Agent Teams 가 활성화되지 않았습니다 (현재 값: '$userVal')"
    $Result['Agent Teams'] = '비활성'
    $Problems.Add('Agent Teams 비활성')
} else {
    Step "Agent Teams 활성화 중..."
    [System.Environment]::SetEnvironmentVariable('CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS', '1', 'User')
    $env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
    if ([System.Environment]::GetEnvironmentVariable('CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS', 'User') -eq '1') {
        Ok "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 설정 완료"
        Info "새로 여는 터미널부터 적용됩니다."
        $Result['Agent Teams'] = '활성'
    } else {
        Fail "환경변수 설정에 실패했습니다. 수동 실행: setx CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS 1"
        $Result['Agent Teams'] = '실패'
        $Problems.Add('Agent Teams 환경변수 설정 실패')
    }
}

# ── 5. harness 플러그인 ──────────────────────────────────────────────────────
Section 5 "harness 플러그인"
if (-not (Installed claude)) {
    Warn "Claude Code 가 없어 플러그인 단계를 건너뜁니다."
    $Result['harness 플러그인'] = '건너뜀'
} else {
    $pluginList = (claude plugin list 2>&1 | Out-String)
    if ($pluginList -match 'harness' -and -not $Force) {
        Ok "harness 플러그인이 이미 설치되어 있습니다."
        $Result['harness 플러그인'] = '설치됨'
    } elseif ($VerifyOnly) {
        Fail "harness 플러그인이 설치되지 않았습니다."
        $Result['harness 플러그인'] = '없음'
        $Problems.Add('harness 플러그인 미설치')
    } else {
        $marketList = (claude plugin marketplace list 2>&1 | Out-String)
        if ($marketList -notmatch 'harness-marketplace') {
            Step "마켓플레이스 추가: revfactory/harness"
            claude plugin marketplace add revfactory/harness 2>&1 | ForEach-Object { Info $_ }
        } else {
            Ok "마켓플레이스가 이미 등록되어 있습니다."
        }

        Step "플러그인 설치: harness@harness-marketplace"
        claude plugin install harness@harness-marketplace --yes 2>&1 | ForEach-Object { Info $_ }

        $pluginList = (claude plugin list 2>&1 | Out-String)
        if ($pluginList -match 'harness') {
            Ok "harness 플러그인 설치 완료"
            $Result['harness 플러그인'] = '설치됨'
        } else {
            Fail "harness 플러그인 설치를 확인할 수 없습니다."
            Info "Claude Code 를 실행한 뒤 입력창에서 직접 시도하세요:"
            Info "  /plugin marketplace add revfactory/harness"
            Info "  /plugin install harness@harness-marketplace"
            $Result['harness 플러그인'] = '확인 필요'
            $Problems.Add('harness 플러그인 설치 확인 필요')
        }
    }
}

# ── 6. 실습 폴더 ─────────────────────────────────────────────────────────────
Section 6 "실습 폴더"
$practice = Join-Path $env:USERPROFILE 'Documents\harness-practice'
if (Test-Path $practice) {
    Ok "실습 폴더 준비됨: $practice"
    $Result['실습 폴더'] = '준비됨'
} elseif ($VerifyOnly) {
    Warn "실습 폴더가 없습니다: $practice"
    $Result['실습 폴더'] = '없음'
} else {
    New-Item -ItemType Directory -Path $practice -Force | Out-Null
    if (Test-Path $practice) {
        Ok "실습 폴더 생성: $practice"
        $Result['실습 폴더'] = '준비됨'
    } else {
        Warn "실습 폴더를 만들지 못했습니다."
        $Result['실습 폴더'] = '실패'
    }
}

# ── 7. (선택) Codex CLI ─────────────────────────────────────────────────────
if ($Codex) {
    Section 7 "Codex CLI (선택)"
    if ((Installed codex) -and (-not $Force)) {
        Ok "codex $((codex --version 2>&1 | Select-Object -First 1))"
        $Result['Codex CLI'] = '설치됨'
    } elseif ($VerifyOnly) {
        Fail "codex 명령어를 찾을 수 없습니다."
        $Result['Codex CLI'] = '없음'
    } else {
        Step "Codex CLI 설치 중..."
        try {
            Invoke-Expression (Invoke-RestMethod -Uri 'https://chatgpt.com/codex/install.ps1')
        } catch {
            Fail "설치 스크립트 실행 실패: $($_.Exception.Message)"
        }
        RefreshEnv
        if (Installed codex) {
            Ok "codex $((codex --version 2>&1 | Select-Object -First 1)) 설치 완료"
            $Result['Codex CLI'] = '설치됨'
        } else {
            Fail "codex 명령어를 찾을 수 없습니다. 터미널을 새로 열어 'codex --version' 을 확인하세요."
            $Result['Codex CLI'] = '확인 필요'
            $Problems.Add('Codex CLI 설치 확인 필요 (터미널 재시작)')
        }
    }

    if (Installed codex) {
        $loginOut = (codex login status 2>&1 | Out-String)
        if ($loginOut -match 'ChatGPT|Logged in|logged in') {
            Ok "Codex 로그인 확인: $($loginOut.Trim() -split "`n" | Select-Object -First 1)"
            $Result['Codex 로그인'] = '완료'
        } else {
            Warn "Codex 에 로그인되어 있지 않습니다."
            Info "터미널에서 'codex login' 실행 → 브라우저에서 ChatGPT 계정(Plus 이상) 로그인"
            $Result['Codex 로그인'] = '확인 필요'
            $Problems.Add('Codex 로그인 필요 — codex login 실행')
        }
    } else {
        $Result['Codex 로그인'] = '건너뜀'
    }
}

# ── 최종 요약 ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host "   최종 점검 결과" -ForegroundColor Cyan
Write-Host "  ==========================================" -ForegroundColor Cyan
foreach ($k in $Result.Keys) {
    $v = $Result[$k]
    $color = switch ($v) {
        '설치됨' { 'Green' }
        '완료'   { 'Green' }
        '활성'   { 'Green' }
        '준비됨' { 'Green' }
        '건너뜀' { 'DarkGray' }
        default  { 'Yellow' }
    }
    Write-Host ("   {0,-20} {1}" -f $k, $v) -ForegroundColor $color
}
Write-Host ""

if ($Problems.Count -eq 0) {
    Write-Host "   모든 항목 준비 완료. 교육 참여 준비가 끝났습니다." -ForegroundColor Green
    Write-Host ""
    Write-Host "   다음 단계 (터미널을 새로 열고 실행):" -ForegroundColor Cyan
    Write-Host "     cd `"$practice`"" -ForegroundColor DarkGray
    Write-Host "     claude" -ForegroundColor DarkGray
    Write-Host "     그리고 입력창에: 하네스 구성해줘" -ForegroundColor DarkGray
} else {
    Write-Host "   남은 할 일:" -ForegroundColor Yellow
    $i = 1
    foreach ($p in $Problems) { Write-Host "     ${i}. $p" -ForegroundColor Yellow; $i++ }
    Write-Host ""
    Write-Host "   해결 후 이 스크립트를 다시 실행하세요 (여러 번 실행해도 안전합니다)." -ForegroundColor DarkGray
    Write-Host "   자세한 해결 방법: https://namojo.github.io/harness-edu/install/setup-windows.html#7-문제-해결" -ForegroundColor DarkGray
}
Write-Host ""

} finally {
    Get-Job -ErrorAction SilentlyContinue | Remove-Job -Force -ErrorAction SilentlyContinue
    if ($transcript) { Stop-Transcript | Out-Null }
    Write-Host "   로그: $LogFile" -ForegroundColor DarkGray
    Write-Host ""
}
