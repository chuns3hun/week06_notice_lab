# 6주차 과제: 비동기 처리 및 공지사항 앱 구현

## 1. 개요 및 실행 방법

### 실행 방법
```bash
# 1. 의존성 패키지 확인
flutter pub get

# 2. 정적 분석 및 종료 코드 확인
flutter analyze

# 3. 앱 실행 (Chrome)
flutter run -d chrome
```

---

## 2. AC (Acceptance Criteria) 검증 기록

| 항목 | 검증 내용 | 관측 결과 | 상태 | 스크린샷 연동 파일명 |
|---|---|---|---|---|
| **AC1** | 초기 화면 진입 시 안내 문구 표시 | `NoticeState.initial` 상태에서 "버튼을 눌러 공지를 확인하세요." 문구 노출 확인 | **통과** | `AC1_initial_screen.png` |
| **AC2** | 요청 버튼 클릭 시 로딩 인디케이터 표시 | `NoticeState.loading` 상태로 전환되며 `CircularProgressIndicator` 노출 확인 | **통과** | `AC2_loading_screen.png` |
| **AC3** | 성공 시 공지사항 문구 표시 | 서버 응답 수신 후 `NoticeState.success` 상태로 전환되며 공지 텍스트 노출 확인 | **통과** | `AC3_success_screen.png` |
| **AC4** | 실패 시 에러 메시지 및 재시도 버튼 표시 | 예외 발생 시 `NoticeState.failure` 상태로 전환되어 에러 메시지 및 "재시도" 버튼 노출 확인 | **통과** | `AC4_failure_screen.png` |
| **AC5** | 로딩 중 중복 클릭 차단 | 로딩 상태에서 버튼 비활성화(`onPressed: null`) 및 연속 클릭 시 요청 횟수가 증가하지 않음 확인 | **통과** | `AC5_duplicate_click.png` |

---

## 3. 화면 및 중복 클릭 요청 횟수 기록

- **초기 상태 요청 횟수:** 0회
- **1회 클릭 후 로딩 상태:** 요청 횟수 1회로 증가 및 로딩 표시
- **로딩 중 5회 연속 클릭 테스트:** 버튼 비활성화 및 로딩 중 재요청 블로킹 로직(`if (_state == NoticeState.loading) return;`) 동작으로 최종 요청 횟수 **1회 유지** 확인

---

## 4. LLM 모델 응답 비교 (A/B)

- **사용 모델:** Claude 3.5 Sonnet vs GPT-4o
- **프롬프트 내용:** "Flutter에서 Future와 setState를 사용하여 로딩, 성공, 실패, 중복 클릭 방지 상태를 관리하는 최소한의 예제 코드를 작성해줘."
- **응답 차이 비교:**
  - **A 모델 (Claude 3.5 Sonnet):** Enum을 활용한 상태 관리 패턴을 제시하여 UI 분기 처리가 직관적이고 가독성이 높았음.
  - **B 모델 (GPT-4o):** Boolean 변수 여러 개(`isLoading`, `isError` 등)를 조합하는 방식을 제시하여 상태 간 충돌 가능성이 존재함.
- **선택 이유:** Enum을 통한 단일 상태 축 방식이 상태 불일치 오류를 방지하고 AC1~AC5의 조건별 화면 분기를 명확히 구현할 수 있어 선택함.

---

## 5. 도구 계약 및 정적 분석 (analyze)

- **도구 명칭:** Dart Static Analyzer (`flutter analyze`)
- **목적:** 코드 내 타입 오류, 미사용 변수, 구문 규칙 위반 여부 사전 검수
- **입력:** `lib/main.dart`, `test/widget_test.dart`
- **출력 및 종료 코드:**

```text
C:\Users\a2738\week06_notice_lab>flutter analyze
Analyzing week06_notice_lab...
No issues found! (ran in 1.7s)
Exit code: 0
```

---

## 6. 비동기 동작 구조 분석 및 한계

### await 전후 상태 변화
1. **`await` 이전:** `_state`를 `loading`으로 변경하고 `_requestCount`를 1 증가시킨 뒤 `setState()`를 호출하여 메인 UI 스레드에 로딩 인디케이터를 반영합니다.
2. **`await` 수행:** `fetchNoticeMock()`의 2초 지연(`Future.delayed`) 작업이 Event Loop의 큐로 들어가 비동기로 처리됩니다. 메인 UI 스레드는 멈추지 않고 이벤트를 수신할 수 있는 상태를 유지합니다.
3. **`await` 이후:** 비동기 작업 완료 후 결과값 반환 또는 예외 발생에 따라 `try-catch` 블록으로 이동하여 `success` 또는 `failure` 상태로 전환하고 UI를 최종 업데이트합니다.

### 오류 처리 구조
- `try-catch` 구문을 적용하여 `fetchNoticeMock()` 내부에서 발생한 Exception을 포착하고, 에러 메시지를 추출하여 사용자 화면에 전파합니다.

### 결과 검증의 한계
- 본 구현은 `Random().nextBool()`을 활용한 모의 서비스(Mocking) 기반이므로 실제 HTTP 통신상의 네트워크 타임아웃, 인코딩 문제, HTTP Status Code(404, 500 등)별 세부 예외처리를 검증하는 데는 한계가 있습니다.

---

## 7. 교재 이해 확인

### 동시성과 병렬성의 차이
- **동시성(Concurrency):** 단일 코어(또는 스레드)가 여러 작업을 아주 짧은 시간 단위로 번갈아 실행하여, 사용자에게 여러 작업이 동시에 진행되는 것처럼 보이게 만드는 구조적 방식입니다.
- **병렬성(Parallelism):** 물리적으로 여러 개의 CPU 코어가 동시에 각기 다른 작업을 같은 시간에 실제로 수행하는 방식입니다.

### 공지 요청에 Future가 적합한 이유
공지사항 조회 기능은 버튼 클릭 시 단 한 번의 요청을 보내고 이에 대한 단일 응답(성공 데이터 또는 실패 에러)을 받는 **단발성 비동기 작업**입니다. 지속적으로 데이터 흐름을 수신해야 하는 `Stream`과 달리, 미래의 단일 값을 반환하는 `Future` 구조가 적합합니다.

### async 키워드와 Isolate
`async` 키워드는 해당 함수가 비동기 단일 작업(`Future`)을 반환하고 내부에서 `await` 구문을 사용할 수 있도록 지정할 뿐입니다. 작업을 다른 Isolate(별도 스레드)로 자동 격리하거나 이동시키지 않습니다. Dart는 기본적으로 단일 스레드 Event Loop 구조로 동작하므로, 무거운 CPU 연산을 별도 Isolate로 분리하려면 `Isolate.run()`을 명시적으로 사용해야 합니다.

---

## 8. Git 저장소 정보 및 커밋 링크

- **개인 Repository:** https://github.com/chuns3hun/week06_notice_lab
- **제출 Commit Link:** https://github.com/chuns3hun/week06_notice_lab/commit/498e3d2