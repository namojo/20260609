# harness-edu — 하네스로 일하는 법

> 일회성 프롬프트에서 **반복 가능한 시스템**으로.
> 코드를 쓰지 않는 실무자를 위한 하네스(Harness) 실습 교육 저장소입니다.
> [revfactory/harness](https://github.com/revfactory/harness) 플러그인을 Claude Code · Codex와 함께 씁니다.

## 교육 사이트

| | |
|---|---|
| **과정 홈** | https://namojo.github.io/harness-edu/ |
| **설치가이드** | https://namojo.github.io/harness-edu/install/ |
| **7차시 커리큘럼** | https://namojo.github.io/harness-edu/chapters/ch1.html |
| **과정 설계 문서** | [`CURRICULUM.md`](CURRICULUM.md) — 대상·차시별 세부 목차·평가 기준 |

---

## 실습 환경 준비

터미널이 처음이어도 됩니다. **[설치가이드](https://namojo.github.io/harness-edu/install/)** 가 명령마다
&ldquo;이렇게 나오면 정상 / 이렇게 나오면 오류&rdquo;를 함께 안내합니다.

| 순서 | 문서 | 소요 |
|---|---|---|
| 1 (필수) | [공통 준비 · Windows](https://namojo.github.io/harness-edu/install/setup-windows.html) / [macOS](https://namojo.github.io/harness-edu/install/setup-mac.html) | 25~35분 |
| 2 (선택) | [Codex CLI](https://namojo.github.io/harness-edu/install/codex.html) — ChatGPT Plus 연동 | 10~15분 |
| 3 (모듈 전용) | [MCP 서버](https://namojo.github.io/harness-edu/install/mcp-server.html) — Tool 실습 | 20~30분 |

**필요한 것**: Claude Pro 이상 구독 · Git · Claude Code · 에이전트 팀 활성화 · Harness 플러그인
**설치하지 않는 것**: Node.js · bun · Docker · WSL2 (Python은 MCP 모듈에서만)

Windows 사용자는 설치 후 [자동 점검 스크립트](https://namojo.github.io/harness-edu/install/setup-windows.ps1)로 빠진 항목을 확인할 수 있습니다.

```powershell
cd "$env:USERPROFILE\Downloads"
irm https://namojo.github.io/harness-edu/install/setup-windows.ps1 -OutFile setup-windows.ps1
Unblock-File .\setup-windows.ps1
.\setup-windows.ps1
```

---

## 수동 설치 요약 (참고)

설치가이드를 따르면 아래는 자동으로 처리됩니다. 순서만 확인하고 싶을 때 보세요.

0. Claude Code 설치 (수동)
```
irm https://claude.ai/install.ps1 | iex
```

2. 경로 추가 (옵션) — claude 경로 설정이 안된 경우에 만
```
$claudePath = "$env:USERPROFILE\.local\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$claudePath*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$claudePath", "User")
}
```

2. Harness 설치
https://github.com/revfactory/harness

```
/plugin marketplace add revfactory/harness
/plugin install harness@harness-marketplace
```

3. Anthropic Skill 설치
https://github.com/anthropics/skills

```
/plugin marketplace add anthropics/skills
/plugin install document-skills@anthropic-agent-skills
```

---

# 학습 지도 (커리큘럼)

하네스로 일하는 법을 **입문 → 실무 → 확장** 순으로 익힙니다. 각 폴더의 README가 독립된 실습입니다.

> 🧭 **혼자 순서대로 따라 하려면 → [`자가학습_가이드.md`](자가학습_가이드.md)** 를 먼저 여세요.
> 무엇을 어떤 순서로, 무엇을 관찰하며, 어디까지 됐으면 다음으로 넘어갈지를 안내합니다.
> 응용 과제는 [`실습.txt`](실습.txt)에 있습니다.

## 1. 입문 — 하네스가 무엇을 바꾸는가

| 폴더 | 무엇을 배우나 | 도구 |
|---|---|---|
| [`xlsx/`](xlsx/) | 표준용어집을 자산화해 반복 데이터 작업을 재현 | Claude Code |
| [`codex/`](codex/) | 단일 → 멀티 → 하네스형 3단계 (코딩 몰라도 OK) | Codex |
| [`harness/`](harness/) | 단일 프롬프트 vs 전문가 에이전트 팀 A/B 비교 | Claude Code + `/harness` |

## 2. 실무 — 매일 돌리는 하네스 엔지니어링 · 🆕

| 폴더 | 무엇을 배우나 | 대상 |
|---|---|---|
| [`codex-engineering/`](codex-engineering/) | Codex 실무 하네스: 샌드박스·승인정책·CI·출력 계약 | 2트랙 |
| ├ [트랙 A · 엔지니어링](codex-engineering/track-a-engineering/) | `codex exec` 패치·`codex review`·CI 게이트 | 개발·데이터 담당 |
| └ [트랙 B · 업무 자동화](codex-engineering/track-b-ops/) | `--search`·`--output-schema`·정례 자동화 | 코드 안 짜는 실무자 |

## 3. 확장 — 에이전트에 없는 능력을 붙이기 · 🆕

| 폴더 | 무엇을 배우나 | 도구 |
|---|---|---|
| [`tool/`](tool/) | 오픈소스 MCP 서버(Python)로 나만의 Tool 만들기 | Claude Code + Codex 공용 |

**세 축 정리** — 하네스는 결국 세 가지의 조합입니다:
- **Agent** (누가) — 역할·경계. `harness/`, `codex/`에서.
- **Skill** (무엇을·어떻게) — 지식·절차. 각 폴더의 `.claude/skills`, `.agents/skills`에서.
- **Tool** (무엇으로 실행) — 결정론적 코드·외부 연동. `tool/`에서. 🆕

입문에서 Agent·Skill을, 실무에서 그것들을 안전하게 반복시키는 엔지니어링을, 확장에서
세 번째 축인 Tool을 직접 만들어 봅니다.
