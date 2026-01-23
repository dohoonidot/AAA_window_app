# 코드베이스 리팩토링 보고서

> **작업일**: 2026-01-23
> **브랜치**: feature/refactoring
> **목적**: 코드 일관성 확보 및 유지보수성 향상

---

## 목차
1. [리팩토링 배경](#1-리팩토링-배경)
2. [변경사항 요약](#2-변경사항-요약)
3. [상세 변경 내용](#3-상세-변경-내용)
4. [개선 효과](#4-개선-효과)
5. [마이그레이션 가이드](#5-마이그레이션-가이드)

---

## 1. 리팩토링 배경

### 1.1 기존 문제점

프로젝트가 기능 구현 중심으로 빠르게 개발되면서 다음과 같은 기술 부채가 누적되었습니다:

#### 문제 1: 폴더 구조 불일치
```
lib/
├── models/           # ❌ 루트에 단독 폴더
├── provider/         # ❌ 루트에 단독 폴더
├── shared/
│   ├── models/       # (비어있음)
│   └── providers/    # 일부 provider만 존재
└── features/
    └── leave/
        └── providers/  # 일부 provider만 존재
```

**문제**: 동일한 역할의 파일들이 여러 위치에 분산되어 있어 새로운 파일을 어디에 만들어야 할지 혼란스러웠습니다.

#### 문제 2: Provider 중복 정의
```dart
// lib/features/leave/leave_providers.dart
final leaveRequestHistoryProvider = StateNotifierProvider<
    LeaveRequestHistoryNotifier,
    AsyncValue<List<LeaveRequestHistory>>>((ref) { ... });

// lib/features/leave/leave_providers_simple.dart (중복!)
final leaveRequestHistoryProvider = StateNotifierProvider<
    LeaveRequestHistoryNotifier,
    List<LeaveRequestHistory>>((ref) { ... });
```

**문제**:
- 같은 이름의 Provider가 다른 타입으로 2개 존재
- 어떤 파일을 import하느냐에 따라 동작이 달라짐
- AsyncValue(에러 처리 포함) vs List(에러 처리 없음) 혼재

#### 문제 3: 공통 원칙 부재
- 코드 작성 가이드라인 없음
- 새 파일 생성 시 위치/네이밍 기준 없음
- 팀원 간 일관성 없는 코드 스타일

---

## 2. 변경사항 요약

| 구분 | 변경 내용 |
|------|----------|
| **문서 생성** | `docs/CODING_GUIDELINES.md` - 코드 작성 공통원칙 |
| **파일 삭제** | `lib/features/leave/leave_providers_simple.dart` |
| **파일 이동** | `lib/models/` → `lib/shared/models/` |
| **파일 이동** | `lib/provider/` → `lib/features/leave/providers/` |
| **코드 수정** | AsyncValue 패턴 적용 (2개 파일) |
| **Import 수정** | 15개 파일의 import 경로 업데이트 |

---

## 3. 상세 변경 내용

### 3.1 공통원칙 문서 생성

#### 생성된 파일
```
docs/CODING_GUIDELINES.md
```

#### 문서 내용
| 섹션 | 설명 |
|------|------|
| 폴더 구조 원칙 | lib/ 최상위 구조, features vs shared 역할 구분 |
| Feature 모듈 구조 | 표준 계층화 (models/, providers/, services/, widgets/) |
| 네이밍 컨벤션 | 파일명, 클래스명, 변수명 규칙 |
| State 관리 원칙 | Riverpod AsyncValue 패턴 필수 사용 |
| Service 레이어 원칙 | Result 패턴으로 에러 처리 통일 |
| 에러 처리 원칙 | 사용자 친화적 메시지, 로깅 분리 |
| 로깅 원칙 | 구조화된 로깅, PII 금지 |
| 파일 크기 제한 | 권장 500줄, 최대 800줄 |

#### 왜 필요했나?
- 새 기능 개발 시 "어디에 파일을 만들까?" 고민 해결
- 코드 리뷰 시 일관된 기준 제공
- 온보딩 시 참고 문서로 활용

---

### 3.2 Provider 중복 제거

#### Before (문제 상황)

**파일 1: `leave_providers.dart`** (AsyncValue 패턴 - 올바른 방식)
```dart
class LeaveRequestHistoryNotifier
    extends StateNotifier<AsyncValue<List<LeaveRequestHistory>>> {

  LeaveRequestHistoryNotifier() : super(const AsyncValue.loading());

  Future<void> loadData(String userId, int year) async {
    state = const AsyncValue.loading();
    try {
      final requests = await LeaveApiService.getLeaveRequestHistory(...);
      state = AsyncValue.data(requests);  // ✅ 성공
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);  // ✅ 에러 처리
    }
  }
}
```

**파일 2: `leave_providers_simple.dart`** (List 직접 반환 - 문제 방식)
```dart
class LeaveRequestHistoryNotifier
    extends StateNotifier<List<LeaveRequestHistory>> {

  LeaveRequestHistoryNotifier() : super([]);

  Future<void> loadData(String userId, int year) async {
    try {
      final requests = await LeaveApiService.getLeaveRequestHistory(...);
      state = requests;  // 성공만 처리
    } catch (e) {
      print('휴가 신청 내역 로드 실패: $e');
      state = [];  // ❌ 에러 시 빈 리스트 (UI에서 구분 불가)
    }
  }
}
```

#### 문제점 분석

| 항목 | leave_providers.dart | leave_providers_simple.dart |
|------|---------------------|----------------------------|
| 상태 타입 | `AsyncValue<List<T>>` | `List<T>` |
| 로딩 상태 | `AsyncValue.loading()` | 없음 |
| 에러 상태 | `AsyncValue.error()` | 빈 리스트 `[]` |
| UI 구현 | `.when(data:, loading:, error:)` | 리스트 직접 사용 |

**실제 발생 문제**:
- `leave_history_table_modal.dart`가 `_simple.dart`를 import
- 에러 발생 시 빈 테이블만 표시 (사용자에게 에러 안내 불가)
- 로딩 중인지 데이터가 없는지 구분 불가

#### After (해결)

**1. 중복 파일 삭제**
```bash
# 삭제됨
lib/features/leave/leave_providers_simple.dart
```

**2. 기존 코드 AsyncValue 패턴으로 수정**

`leave_history_table_modal.dart` 변경:
```dart
// Before
@override
Widget build(BuildContext context) {
  final leaveHistory = ref.watch(leaveRequestHistoryProvider);
  final sortedHistory = _getSortedAndFilteredHistory(leaveHistory);
  return Dialog(...);
}

// After
@override
Widget build(BuildContext context) {
  final leaveHistoryAsync = ref.watch(leaveRequestHistoryProvider);

  return leaveHistoryAsync.when(
    data: (leaveHistory) => _buildContent(context, leaveHistory),
    loading: () => Dialog(
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (error, stack) => Dialog(
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            Text('데이터를 불러오는데 실패했습니다.\n$error'),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('닫기'),
            ),
          ],
        ),
      ),
    ),
  );
}
```

`admin_leave_approval_screen.dart` 변경:
```dart
// Before
final leaveHistory = ref.watch(leaveRequestHistoryProvider);
pendingCount = leaveHistory
    .where((h) => h.status == LeaveRequestStatus.pending)
    .length;

// After
final leaveHistoryAsync = ref.watch(leaveRequestHistoryProvider);
final leaveHistory = leaveHistoryAsync.valueOrNull ?? [];  // 로딩/에러 시 빈 리스트
pendingCount = leaveHistory
    .where((h) => h.status == LeaveRequestStatus.pending)
    .length;
```

#### 왜 이렇게 했나?

1. **AsyncValue가 더 나은 패턴**: 로딩/성공/에러 3가지 상태를 명확히 구분
2. **사용자 경험 향상**: 에러 발생 시 적절한 피드백 제공 가능
3. **단일 소스**: 동일 기능에 대해 하나의 정의만 존재해야 함
4. **leave_providers.dart 선택 이유**: 이미 AsyncValue 패턴을 올바르게 구현하고 있었음

---

### 3.3 전역 폴더 정리

#### Before (문제 상황)

```
lib/
├── models/                              # ❌ 루트에 단독 존재
│   ├── contest_models.dart
│   └── leave_management_models.dart
├── provider/                            # ❌ 루트에 단독 존재
│   └── leave_management_provider.dart
├── shared/
│   ├── models/                          # (비어있음)
│   ├── providers/
│   │   ├── providers.dart
│   │   ├── chat_notifier.dart
│   │   └── admin_management_provider.dart
│   └── ...
└── features/
    └── leave/
        ├── providers/
        │   ├── leave_notification_provider.dart
        │   └── vacation_recommendation_provider.dart
        └── ...
```

**문제점**:
1. `lib/models/`와 `lib/shared/models/` 두 곳에 모델이 분산될 수 있음
2. `lib/provider/`와 `lib/shared/providers/` 역할 구분 불명확
3. 새 파일 생성 시 어느 폴더에 넣어야 할지 혼란

#### After (개선)

```
lib/
├── shared/
│   ├── models/                          # ✅ 전역 공유 모델 통합
│   │   ├── contest_models.dart          # (이동됨)
│   │   └── leave_management_models.dart # (이동됨)
│   ├── providers/
│   │   ├── providers.dart
│   │   ├── chat_notifier.dart
│   │   └── admin_management_provider.dart
│   └── ...
└── features/
    └── leave/
        ├── providers/                   # ✅ leave 전용 provider 통합
        │   ├── leave_notification_provider.dart
        │   ├── vacation_recommendation_provider.dart
        │   └── leave_management_provider.dart  # (이동됨)
        └── ...
```

#### 파일 이동 상세

| 원래 위치 | 새 위치 | 이동 이유 |
|----------|---------|----------|
| `lib/models/contest_models.dart` | `lib/shared/models/` | 여러 feature에서 사용하는 전역 모델 |
| `lib/models/leave_management_models.dart` | `lib/shared/models/` | 여러 feature에서 사용하는 전역 모델 |
| `lib/provider/leave_management_provider.dart` | `lib/features/leave/providers/` | leave 기능 전용 provider |

#### Import 경로 변경

**총 15개 파일 수정**

```dart
// Before
import 'package:ASPN_AI_AGENT/models/leave_management_models.dart';
import 'package:ASPN_AI_AGENT/provider/leave_management_provider.dart';

// After
import 'package:ASPN_AI_AGENT/shared/models/leave_management_models.dart';
import 'package:ASPN_AI_AGENT/features/leave/providers/leave_management_provider.dart';
```

**수정된 파일 목록**:
1. `lib/main.dart`
2. `lib/ui/screens/chat_home_page_v5.dart`
3. `lib/ui/screens/leave_management_screen.dart`
4. `lib/ui/screens/admin_leave_approval_screen.dart`
5. `lib/features/leave/leave_draft_modal.dart`
6. `lib/features/leave/leave_request_manual_modal.dart`
7. `lib/features/leave/leave_calendar_modal.dart`
8. `lib/features/leave/full_calendar_modal.dart`
9. `lib/features/leave/approver_selection_modal.dart`
10. `lib/features/leave/annual_leave_notice_screen.dart`
11. `lib/features/leave/leave_providers.dart`
12. `lib/features/leave/providers/leave_management_provider.dart`
13. `lib/features/leave/services/leave_realtime_service.dart`
14. `lib/shared/services/api_service.dart`
15. `lib/shared/services/leave_api_service.dart`
16. `lib/shared/adapters/admin_data_adapter.dart`
17. `lib/shared/providers/admin_management_provider.dart`

#### 왜 이렇게 했나?

1. **명확한 책임 분리**
   - `shared/models/`: 여러 feature에서 공유하는 모델
   - `features/<name>/providers/`: 해당 feature 전용 provider

2. **일관된 구조**
   - 새 모델 생성 시: "공유인가? → `shared/models/`, feature 전용인가? → `features/<name>/models/`"
   - 명확한 기준으로 고민 시간 단축

3. **루트 레벨 정리**
   - `lib/` 루트에는 `main.dart`만 존재
   - 모든 코드는 `core/`, `features/`, `shared/`, `ui/`, `update/` 하위에 위치

---

## 4. 개선 효과

### 4.1 코드 품질 향상

| 항목 | Before | After | 개선 |
|------|--------|-------|------|
| Provider 중복 | 2개 파일 (같은 이름, 다른 타입) | 1개 파일 | 혼란 제거 |
| 루트 레벨 폴더 | 2개 (`models/`, `provider/`) | 0개 | 구조 정리 |
| 에러 처리 | 일부만 AsyncValue | 전체 AsyncValue | 일관성 확보 |
| 코드 가이드 | 없음 | CODING_GUIDELINES.md | 기준 수립 |

### 4.2 개발자 경험 향상

#### 새 파일 생성 시
```
Before: "models 폴더가 lib/에도 있고 shared/에도 있는데 어디에 만들지?"
After:  "공유 모델이니까 shared/models/에 만들면 됨" (CODING_GUIDELINES.md 참조)
```

#### 코드 리뷰 시
```
Before: "이 Provider 왜 List로 반환해? AsyncValue 써야 하는 거 아냐?"
After:  "공통원칙에 AsyncValue 패턴 필수라고 되어있으니 수정 필요"
```

#### 에러 디버깅 시
```
Before: 빈 화면만 표시됨 → 에러인지 로딩인지 데이터 없음인지 구분 불가
After:  에러 메시지 표시 → "데이터를 불러오는데 실패했습니다" + 상세 에러
```

### 4.3 사용자 경험 향상

#### 휴가 내역 테이블 모달
```
Before:
- API 에러 시 → 빈 테이블 표시 (사용자: "왜 내역이 없지?")
- 로딩 중 → 빈 테이블 표시 (사용자: "로딩 중인가?")

After:
- API 에러 시 → 에러 아이콘 + "데이터를 불러오는데 실패했습니다" + 닫기 버튼
- 로딩 중 → 로딩 인디케이터 표시
- 성공 시 → 정상적인 테이블 표시
```

---

## 5. 마이그레이션 가이드

### 5.1 기존 코드에서 import 에러 발생 시

에러 메시지:
```
Target of URI doesn't exist: 'package:ASPN_AI_AGENT/models/leave_management_models.dart'
```

해결:
```dart
// 변경 전
import 'package:ASPN_AI_AGENT/models/leave_management_models.dart';

// 변경 후
import 'package:ASPN_AI_AGENT/shared/models/leave_management_models.dart';
```

### 5.2 Provider import 에러 발생 시

에러 메시지:
```
Target of URI doesn't exist: 'package:ASPN_AI_AGENT/provider/leave_management_provider.dart'
```

해결:
```dart
// 변경 전
import 'package:ASPN_AI_AGENT/provider/leave_management_provider.dart';

// 변경 후
import 'package:ASPN_AI_AGENT/features/leave/providers/leave_management_provider.dart';
```

### 5.3 leave_providers_simple.dart import 에러 발생 시

에러 메시지:
```
Target of URI doesn't exist: 'package:ASPN_AI_AGENT/features/leave/leave_providers_simple.dart'
```

해결:
```dart
// 변경 전
import 'package:ASPN_AI_AGENT/features/leave/leave_providers_simple.dart';

// 변경 후
import 'package:ASPN_AI_AGENT/features/leave/leave_providers.dart';
```

**주의**: `leave_providers.dart`는 `AsyncValue<List<T>>`를 반환하므로, 사용하는 코드도 수정 필요:

```dart
// 변경 전 (List 직접 사용)
final leaveHistory = ref.watch(leaveRequestHistoryProvider);
for (var item in leaveHistory) { ... }

// 변경 후 (AsyncValue 처리)
// 방법 1: when 패턴 (권장)
ref.watch(leaveRequestHistoryProvider).when(
  data: (leaveHistory) => ...,
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('에러: $e'),
);

// 방법 2: valueOrNull (간단한 경우)
final leaveHistory = ref.watch(leaveRequestHistoryProvider).valueOrNull ?? [];
for (var item in leaveHistory) { ... }
```

---

## 부록: 변경된 파일 전체 목록

### 생성된 파일
- `docs/CODING_GUIDELINES.md`
- `docs/REFACTORING.md` (이 문서)

### 삭제된 파일
- `lib/features/leave/leave_providers_simple.dart`

### 이동된 파일
- `lib/models/contest_models.dart` → `lib/shared/models/contest_models.dart`
- `lib/models/leave_management_models.dart` → `lib/shared/models/leave_management_models.dart`
- `lib/provider/leave_management_provider.dart` → `lib/features/leave/providers/leave_management_provider.dart`

### 삭제된 디렉토리
- `lib/models/`
- `lib/provider/`

### 수정된 파일 (Import 경로 변경)
1. `lib/main.dart`
2. `lib/ui/screens/chat_home_page_v5.dart`
3. `lib/ui/screens/leave_management_screen.dart`
4. `lib/ui/screens/admin_leave_approval_screen.dart`
5. `lib/features/leave/leave_draft_modal.dart`
6. `lib/features/leave/leave_request_manual_modal.dart`
7. `lib/features/leave/leave_calendar_modal.dart`
8. `lib/features/leave/full_calendar_modal.dart`
9. `lib/features/leave/approver_selection_modal.dart`
10. `lib/features/leave/annual_leave_notice_screen.dart`
11. `lib/features/leave/leave_providers.dart`
12. `lib/features/leave/providers/leave_management_provider.dart`
13. `lib/features/leave/services/leave_realtime_service.dart`
14. `lib/shared/services/api_service.dart`
15. `lib/shared/services/leave_api_service.dart`
16. `lib/shared/adapters/admin_data_adapter.dart`
17. `lib/shared/providers/admin_management_provider.dart`

### 수정된 파일 (코드 변경)
1. `lib/features/leave/leave_history_table_modal.dart` - AsyncValue.when() 패턴 적용
2. `lib/ui/screens/admin_leave_approval_screen.dart` - valueOrNull 패턴 적용
