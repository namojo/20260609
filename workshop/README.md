# workshop — 하네스 엔지니어링 워크샵 실습 파일

교재: **https://namojo.github.io/harness-edu2**

이 폴더에 이 과정의 실습 파일이 전부 들어 있습니다. 저장소의 다른 폴더(`xlsx/`, `ad/`, `codex/`, `harness/`, `map/`, `tool/`, `slide/`, `dashboard/`)는 **이전 7차시 과정 자료**이며 이 과정에서는 쓰지 않습니다.

## 구성

| 폴더 | 실습 | 입력 파일 |
|---|---|---|
| `practice-1-youtube/` | 실습 1 · 유튜브 콘텐츠 기획 팀 | 없음 (브리프 한 편) |
| `practice-2-marketing/` | 실습 2 · 브랜드 마케팅 전략보고서 | 없음 (브리프 한 편) |
| `practice-3-pptx/` | 실습 3 · 샘플 형식으로 새 PPT | `sample.pptx` + 실습 2의 산출물 |

각 폴더의 `README.md`에 브리프 원문이 그대로 들어 있습니다. **오프라인에서도 실습이 됩니다.**

## 시작 전 준비

```
/plugin marketplace add revfactory/harness
/plugin install harness@harness-marketplace
```

설치가 안 되어 있으면 교재의 [설치가이드](https://namojo.github.io/harness-edu2/install/)를 먼저 보세요. Claude Pro / Max / Team / Enterprise 중 하나가 필요하고, **API Key는 필요하지 않습니다.**

## 세 실습의 관계

```
실습 1  팀을 만든다      도메인 문장 → 전문 역할
   ↓
실습 2  구조를 고른다    독립 조사 → 통합 → 별도 검토
   ↓          └────── 산출물을 실습 3의 입력으로 ──────┐
실습 3  산출물을 다듬는다  샘플 형식 규칙 + 전략 → 편집 가능한 PPT 3장
```

실습 3은 실습 2의 결과물을 씁니다. 실습 2를 건너뛰었다면 `practice-3-pptx/example-strategy.md` 를 대신 쓰면 됩니다.
