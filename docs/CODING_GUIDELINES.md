# Flutter 코드 작성 공통원칙

> 이 문서는 프로젝트의 코드 일관성과 유지보수성을 위한 공통 원칙을 정의합니다.
> **참조 모델**: `lib/features/leave/` 모듈 구조

---

## 1. 폴더 구조 원칙

### 1.1 최상위 구조

```
lib/
├── core/              # 인프라: config, database, mixins, constants
├── features/          # 기능 모듈 (도메인별 분리)
├── shared/            # 공유 컴포넌트
│   ├── models/        # 전역 공유 모델
│   ├── providers/     # 전역 상태 관리
│   ├── services/      # 공유 서비스 (API, AMQP 등)
│   ├── utils/         # 유틸리티 함수
│   └── widgets/       # 공유 UI 컴포넌트
├── ui/                # 전역 UI
│   ├── screens/       # 메인 화면
│   └── theme/         # 테마 및 스타일
├── update/            # 앱 업데이트 관련
└── main.dart
```

### 1.2 원칙

| 원칙 | 설명 |
|------|------|
| **Single Responsibility** | 각 폴더는 단일 책임을 가짐 |
| **Feature Independence** | features 간 직접 참조 금지 (shared를 통해 공유) |
| **No Root-Level Orphans** | lib/ 루트에 단독 폴더/파일 금지 (models/, provider/ 등) |

### 1.3 features vs shared

| 구분 | features/ | shared/ |
|------|-----------|---------|
| **용도** | 도메인별 기능 모듈 | 전역 공유 컴포넌트 |
| **접근** | 해당 feature 내부에서만 | 모든 feature에서 접근 가능 |
| **예시** | leave, approval, chat | ApiService, ChatNotifier |

---

## 2. Feature 모듈 구조

### 2.1 표준 구조 (파일 5개 이상)

```
features/<feature_name>/
├── models/                    # 도메인 데이터 모델
│   └── <feature>_model.dart
├── providers/                 # 상태 관리 (Riverpod)
│   └── <feature>_provider.dart
├── services/                  # 비즈니스 로직
│   └── <feature>_service.dart
├── widgets/                   # 재사용 UI 컴포넌트
│   └── <feature>_widget.dart
├── <feature>_screen.dart      # 메인 화면 (루트)
└── AGENTS.md                  # 모듈 가이드 문서
```

### 2.2 소규모 구조 (파일 4개 이하)

```
features/<feature_name>/
├── <feature>_model.dart
├── <feature>_provider.dart
├── <feature>_screen.dart
└── <feature>_widget.dart
```

### 2.3 원칙

- **모델 위치**: feature 전용 → `features/<name>/models/`, 공유 → `shared/models/`
- **Provider 위치**: feature 전용 → `features/<name>/providers/`, 전역 → `shared/providers/`
- **중복 금지**: 동일 기능의 파일 2개 이상 금지 (예: `_simple.dart` 패턴 금지)
- **문서화**: 복잡한 feature는 `AGENTS.md` 포함

---

## 3. 네이밍 컨벤션

### 3.1 파일명

**규칙**: `snake_case` + 의미있는 접미사

| 유형 | 접미사 | 예시 |
|------|--------|------|
| 화면 | `_screen.dart` 또는 `_page.dart` | `leave_management_screen.dart` |
| 모달 | `_modal.dart` | `leave_draft_modal.dart` |
| 위젯 | `_widget.dart` 또는 `_widgets.dart` | `leave_loading_widgets.dart` |
| 프로바이더 | `_provider.dart` | `leave_notification_provider.dart` |
| 서비스 | `_service.dart` | `leave_api_service.dart` |
| 모델 | `_model.dart` 또는 `_models.dart` | `vacation_recommendation_model.dart` |
| 설정 | `_config.dart` | `app_config.dart` |

### 3.2 클래스명

**규칙**: `PascalCase`

```dart
// State 클래스
class LeaveManagementState { }

// Notifier 클래스
class LeaveManagementNotifier extends StateNotifier<LeaveManagementState> { }

// Service 클래스
class LeaveApiService { }

// Model 클래스
class LeaveBalance { }
```

### 3.3 Provider 명명

```dart
// StateNotifierProvider
final leaveManagementProvider = StateNotifierProvider<
    LeaveManagementNotifier,
    LeaveManagementState>((ref) => ...);

// StateProvider (단순 값)
final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

// Provider (읽기 전용)
final leaveBalanceListProvider = Provider<List<LeaveBalance>>((ref) => ...);
```

### 3.4 변수명

**규칙**: `camelCase`

```dart
// Boolean 변수: is/has 접두사
final bool isLoading = false;
final bool hasNewGift = false;

// Private 변수: _ 접두사
bool _isConnecting = false;
Timer? _reconnectTimer;

// 상수: k 접두사 또는 SCREAMING_SNAKE_CASE
const kDefaultPadding = 16.0;
const int MAX_RETRY_COUNT = 3;
```

---

## 4. State 관리 원칙 (Riverpod)

### 4.1 Provider 유형 선택

| 유형 | 용도 | 예시 |
|------|------|------|
| `StateProvider` | 단순 값 (boolean, int, String) | `selectedYearProvider` |
| `StateNotifierProvider` | 복잡한 상태 + 로직 | `leaveManagementProvider` |
| `FutureProvider` | 일회성 비동기 데이터 | `userProfileProvider` |
| `StreamProvider` | 실시간 데이터 | `notificationStreamProvider` |

### 4.2 상태 클래스 패턴

```dart
class LeaveManagementState {
  final LeaveManagementData? data;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const LeaveManagementState({
    this.data,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  // copyWith 필수 구현
  LeaveManagementState copyWith({
    LeaveManagementData? data,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return LeaveManagementState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // reset 메서드 권장
  LeaveManagementState reset() {
    return const LeaveManagementState();
  }
}
```

### 4.3 AsyncValue 패턴 (권장)

```dart
// StateNotifier with AsyncValue
class LeaveRequestHistoryNotifier
    extends StateNotifier<AsyncValue<List<LeaveRequestHistory>>> {

  LeaveRequestHistoryNotifier() : super(const AsyncValue.loading());

  Future<void> loadData(String userId, int year) async {
    state = const AsyncValue.loading();

    try {
      final requests = await LeaveApiService.getLeaveRequestHistory(
        userId: userId,
        year: year,
      );
      state = AsyncValue.data(requests);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void resetState() {
    state = const AsyncValue.loading();
  }
}

// UI에서 사용
ref.watch(leaveRequestHistoryProvider).when(
  data: (requests) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => ErrorWidget(e.toString()),
);
```

### 4.4 원칙

- **AsyncValue 활용**: 로딩/에러/성공 상태 통합 관리
- **불변성 유지**: copyWith 패턴 필수
- **단일 소스**: 동일 데이터에 대한 Provider 중복 금지
- **초기화 메서드**: 로그아웃 시 `resetState()` 호출

---

## 5. Service 레이어 원칙

### 5.1 API Service 패턴

```dart
class LeaveApiService {
  static String get serverUrl => AppConfig.baseUrl;

  /// 휴가 잔여량 조회
  static Future<List<LeaveBalance>> getLeaveBalance({
    required String userId,
  }) async {
    final url = Uri.parse('$serverUrl/leave/balance');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'user_id': userId});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['balances'] as List)
            .map((e) => LeaveBalance.fromJson(e))
            .toList();
      } else {
        throw Exception('휴가 잔여량 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('휴가 잔여량 조회 실패: $e');
    }
  }
}
```

### 5.2 Result 패턴 (권장 - 향후 적용)

```dart
// Result 클래스 정의
class Result<T> {
  final T? data;
  final String? error;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

// Service에서 사용
static Future<Result<List<LeaveBalance>>> getLeaveBalance({
  required String userId,
}) async {
  try {
    final response = await http.post(...);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Result.success(
        (data['balances'] as List)
            .map((e) => LeaveBalance.fromJson(e))
            .toList(),
      );
    } else {
      return Result.failure('휴가 잔여량 조회 실패');
    }
  } catch (e) {
    return Result.failure('요청 실패: $e');
  }
}
```

### 5.3 원칙

- **static 메서드**: 인스턴스 불필요 시 static 사용
- **단일 책임**: 하나의 Service는 하나의 도메인만 담당
- **에러 메시지**: 사용자 친화적 한글 메시지 사용

---

## 6. 에러 처리 원칙

### 6.1 API 에러 처리

```dart
// Provider에서 에러 처리
Future<void> loadData(String userId) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final data = await LeaveApiService.getLeaveManagement(userId);
    state = state.copyWith(data: data, isLoading: false);
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: '데이터를 불러오는데 실패했습니다. 다시 시도해주세요.',
    );
  }
}
```

### 6.2 UI 에러 표시

| 유형 | 사용 시점 | 예시 |
|------|----------|------|
| **스낵바** | 일시적 에러 알림 | 네트워크 오류 |
| **인라인 메시지** | 폼 유효성 에러 | 필수 항목 누락 |
| **전체 화면 에러** | 데이터 로드 실패 | 빈 화면 대체 |

### 6.3 원칙

- **사용자 친화적 메시지**: 기술적 에러 대신 이해 가능한 메시지
- **로깅 분리**: 사용자 메시지와 디버그 로그 분리
- **복구 가능성**: 가능한 경우 재시도 옵션 제공

---

## 7. 로깅 원칙

### 7.1 현재 패턴 (개선 필요)

```dart
// 이모지 기반 로깅 (현재 사용 중)
print('🔍 ChatProvider: User ID가 null입니다.');
print('✅ [AMQP] 연결 성공');
print('⚠️ [API] 요청 실패: $e');
```

### 7.2 권장 패턴

```dart
// 태그 기반 구조화 로깅
class AppLogger {
  static void info(String tag, String message) {
    if (kDebugMode) {
      print('[$tag] INFO: $message');
    }
  }

  static void error(String tag, String message, [dynamic error]) {
    if (kDebugMode) {
      print('[$tag] ERROR: $message ${error ?? ''}');
    }
  }

  static void debug(String tag, String message) {
    if (kDebugMode) {
      print('[$tag] DEBUG: $message');
    }
  }
}

// 사용 예시
AppLogger.info('LeaveService', '휴가 신청 완료');
AppLogger.error('ApiService', 'API 호출 실패', e);
```

### 7.3 원칙

- **PII 금지**: 개인정보(userId, 비밀번호, 이름 등) 로깅 금지
- **태그 필수**: 출처 식별을 위한 태그 포함
- **레벨 준수**: 운영=ERROR/WARN, 개발=DEBUG/INFO
- **kDebugMode 활용**: 릴리스 빌드에서 로그 제외

---

## 8. 파일 크기 제한

### 8.1 기준

| 기준 | 줄 수 | 설명 |
|------|------|------|
| **권장 최대** | 500줄 | 단일 파일 권장 최대 |
| **절대 한계** | 800줄 | 이 이상 시 반드시 분리 |
| **함수 최대** | 50줄 | 단일 함수 권장 최대 |

### 8.2 분리 전략

대형 파일 발생 시 다음 순서로 분리:

1. **위젯 분리**: 재사용 가능한 서브 위젯으로 분리 → `widgets/`
2. **로직 분리**: 복잡한 로직은 Service/Utils로 이동 → `services/`
3. **상태 분리**: 관련 상태는 별도 Provider로 분리 → `providers/`

### 8.3 분리 예시

```
# Before (4,141줄)
common_electronic_approval_modal.dart

# After
features/approval/
├── common_electronic_approval_modal.dart (~300줄, 메인)
├── widgets/
│   ├── approval_form_section.dart (~200줄)
│   ├── approval_line_section.dart (~200줄)
│   └── attachment_section.dart (~150줄)
├── services/
│   └── approval_form_service.dart (~300줄)
└── providers/
    └── approval_form_provider.dart (~200줄)
```

---

## 9. 안티패턴 (하지 말아야 할 것)

### 9.1 폴더 구조

```dart
// ❌ lib 루트에 단독 폴더
lib/models/              // → lib/shared/models/로 이동
lib/provider/            // → lib/features/<name>/providers/로 이동

// ❌ Feature 간 직접 참조
import '../leave/leave_models.dart';  // approval에서 leave 직접 참조
// → shared/models/로 공유 모델 이동
```

### 9.2 State 관리

```dart
// ❌ Provider 중복 정의
// leave_providers.dart
final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);
// leave_providers_simple.dart
final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);
// → 단일 파일로 통합

// ❌ UI에서 직접 API 호출
class _MyWidgetState extends State<MyWidget> {
  Future<void> loadData() async {
    final data = await http.get(...);  // ❌
  }
}
// → Provider를 통해 데이터 로드
```

### 9.3 코드 품질

```dart
// ❌ 민감 정보 로깅
print('로그인 성공: userId=$userId, password=$password');  // ❌

// ❌ BuildContext를 비동기 경계 넘어서 사용
Future<void> doSomething() async {
  await Future.delayed(Duration(seconds: 1));
  Navigator.pop(context);  // ❌ mounted 체크 없음
}
// → if (mounted) Navigator.pop(context);

// ❌ 전역 변수로 상태 관리
String? globalUserId;  // ❌
// → Provider 사용
```

---

## 10. 체크리스트

### 새 파일 생성 시

- [ ] 올바른 폴더에 위치하는가?
- [ ] 네이밍 컨벤션을 따르는가?
- [ ] 500줄 이하인가?
- [ ] 중복 파일이 없는가?

### 새 Provider 생성 시

- [ ] 적절한 Provider 유형을 선택했는가?
- [ ] AsyncValue 또는 copyWith 패턴을 사용하는가?
- [ ] resetState() 메서드가 있는가?
- [ ] 동일 기능 Provider가 이미 존재하지 않는가?

### 새 Service 생성 시

- [ ] 단일 도메인만 담당하는가?
- [ ] 에러 처리가 적절한가?
- [ ] 사용자 친화적 에러 메시지를 사용하는가?

### PR 제출 전

- [ ] `flutter analyze` 오류 없음
- [ ] `flutter build windows --debug` 성공
- [ ] 기능 동작 테스트 완료
- [ ] 새 로깅에 PII 포함되지 않음

---

## 참조

- **모범 사례 모듈**: `lib/features/leave/` - 계층화된 구조의 참조 모델
- **모범 사례 문서**: `lib/features/leave/AGENTS.md` - Feature 문서화 참조
- **상태 관리**: [Riverpod 공식 문서](https://riverpod.dev/)
