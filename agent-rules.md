# WanderCard — Agent Rules

> 팀의 실제 운영 경험에서 도출한 규칙. 매번 같은 실수 반복하지 않도록 기록.

---

## 1. ACP(Codex) 세션 spawn 방식

### ✅ 올바른 방식: Webhook 기반 (독서잔디 패턴)

Danny가 `sessions_spawn`으로 ACP 세션 열 때, **webhook/relay 설정에서 Codex가 직접 스레드에 메시지를 보내도록** 해야 함.

- Codex 응답이 **Codex 전용 bot 프로필**로 표시됨
- Gary가 Codex 응답을 직접 볼 수 있음
- 독서잔디 때 이 방식으로 성공

### ❌ 잘못된 방식: Task relay (WanderCard에서 발생한 문제)

`sessions_spawn(task="...")` 방식으로 열면:
- Codex 응답이 Dani 봇을 통해 relay됨
- Dani 프로필로만 표시됨 (Codex bot 프로필 안 뜸)
- 같은 내용이 두 번 중복 표시될 수 있음 (Dani + Codex)

### 규칙

> **ACP 세션은 항상 webhook/relay로 Codex가 직접 발신하도록 설정한다.**
> `sessions_spawn`의 `task`에 초기 지시를 때려넣는 대신, 스레드만 먼저 열고 Eli가 task를 던지는 방식으로 진행한다.

---

## 2. GitHub 계정 및 PR 규칙

### 계정 사용 원칙
- **저장소 생성**: 반드시 `garibong-labs` 계정으로
- **PR 생성**: 반드시 작업한 에이전트 본인 계정으로 (`agent-eli`, `agent-dani`)
- **gh auth는 글로벌 상태** — 전후로 `gh auth status` 확인 필수

### 래퍼 스크립트
- Eli: `~/.openclaw/workspace/scripts/gh-eli.sh`
- Dani: `~/.openclaw/workspace/scripts/gh-dani.sh`
- `gh pr create`, `gh pr close`, `gh issue create` 등 쓰기 작업은 반드시 래퍼 사용
- PR 생성 후 `gh pr view <번호> --json author --jq '.author.login'`으로 author 확인

### Collabrators
- `garibong-labs` 저장소 Collaborator 초대는 Gary가 직접 Settings에서 진행
- Fork보다 Collaborator 초대가 효율적 (push 권한 부여)

---

## 3. 작업 파이프라인 (독서잔디 → WanderCard)

```
Gary: 방향 제시 → Dani: 기획서 작성 → Dani: HTML/CSS 화면 설계서
→ Eli: 구현 명세서 작성 → Codex(ACP): 실제 구현 → Eli: 진행 관리/검증
```

- ACP 세션은 Dani가 스레드만 열면, Eli가 task 던짐 (자동 시작 아님)
- 각 단계 완료 시 빌드 확인 필수 (evidence: BUILD SUCCEEDED 로그)
- 상태 보고는 증거 포함 (PID, 파일 경로, URL, 명령어 출력) — "done" 금지

---

## 4. 빌드 규칙

- xcodegen + xcodebuild 사용 (Swift Package Manager 안 씀)
- 시뮬레이터: iPhone 17 Pro (ID: `A27E421A-0F1D-4972-9A59-A6AB7221DD1C`)
- `CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO` 필수
- 매 단계마다 `xcodebuild build` 통과 확인 후 다음 단계

## 5. 스크린샷 공유 규칙

**시뮬레이터 스크린샷은 항상 이 Discord 채널 (`#ideas-poc-and-skills` 및 현재 프로젝트 스레드)에 직접 업로드한다.**

- Gary가 별도 클릭 없이 바로 볼 수 있어야 함 (스레드 외부 메시지 금지)
- `filePath`는 `~/.openclaw/workspace/` 또는 `.openclaw/media/inbound/` 하위 경로만 허용
- `/tmp/` 경로 사용 금지 — workspace 내에서만 작업
- 스크린샷은 항상 간단한 설명/피드백과 함께 공유 (캡션 필수)
- 같은 화면 변화 전/후 비교 시 두 이미지 같이 올림

---

*Last updated: 2026-04-05*
