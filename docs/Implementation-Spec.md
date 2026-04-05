# WanderCard — 구현 명세서 (Implementation Spec)

> **작성일:** 2026-04-05
> **작성자:** Eli (Technical Lead)
> **참조:** Plan.md, docs/mockups/ (01-home.html ~ 04-card-preview.html)
> **대상:** PoC Phase 1 MVP

---

## 1. 프로젝트 구조

```
WanderCard/
├── WanderCard.xcodeproj
├── WanderCard/                    # Main App Target
│   ├── App/
│   │   └── WanderCardApp.swift    # @main
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── Trip.swift         # SwiftData entity
│   │   │   └── TravelCard.swift   # SwiftData entity
│   │   ├── Services/
│   │   │   ├── PhotoLibraryService.swift   # PhotosKit wrapper
│   │   │   └── CardRenderer.swift          # Core Graphics renderer
│   │   └── ViewModels/
│   │       ├── TripsViewModel.swift
│   │       ├── TripDetailViewModel.swift
│   │       └── CreateCardViewModel.swift
│   ├── Features/
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   └── TripListCard.swift
│   │   ├── TripDetail/
│   │   │   └── TripDetailView.swift
│   │   ├── CreateCard/
│   │   │   ├── CreateCardView.swift
│   │   │   ├── PhotoPickerSheet.swift
│   │   │   ├── TemplateSelectorView.swift
│   │   │   └── CardContentView.swift
│   │   ├── CardPreview/
│   │   │   └── CardPreviewView.swift
│   │   └── Onboarding/
│   │       └── OnboardingView.swift
│   ├── Templates/
│   │   ├── CardTemplate.swift         # Template enum + config
│   │   ├── LightTemplate.swift        # 일기풍
│   │   ├── DarkTemplate.swift         # 감성풍
│   │   └── MinimalTemplate.swift      # 인스타용
│   ├── Shared/
│   │   ├── Components/
│   │   │   ├── ImageLoaderView.swift
│   │   │   └── GradientView.swift
│   │   └── Extensions/
│   │       ├── Date+Extensions.swift
│   │       └── CGImage+Extensions.swift
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Info.plist                 # NSPhotoLibraryUsageDescription
│   │   └── Fonts/                     # Custom fonts (if needed)
│   └── Preview Content/
│       └── PreviewAssets.xcassets     # Sample images
├── ShareExtension/                    # Share Extension Target
│   ├── Info.plist                     # NSExtension activation rules
│   ├── ShareViewController.swift      # UINavigationController root
│   ├── ShareRootView.swift            # SwiftUI bridge
│   └── ShareViewModel.swift
└── WanderCardTests/
    ├── CardRendererTests.swift
    └── TripTests.swift
```

---

## 2. 데이터 모델 (SwiftData)

### 2.1 Trip (여행)

```swift
@Model
final class Trip {
    var id: UUID = UUID()
    var name: String                  // "2024.06 도쿄"
    var startDate: Date
    var endDate: Date
    var photoCount: Int = 0
    var cardCount: Int = 0
    var coverImageLocalPath: String?  // Local thumbnail URL
    var cards: [TravelCard] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Computed
    var durationDays: Int { ... }
}
```

### 2.2 TravelCard (생성된 카드)

```swift
@Model
final class TravelCard {
    var id: UUID = UUID()
    var tripId: UUID                  // Relationship to Trip
    var photoLocalIdentifier: String  // PHAsset.localIdentifier
    var textContent: String?          // Shared text or manual input
    var sourceURL: URL?               // If shared via Share Extension
    var templateType: CardTemplateType // .light, .dark, .minimal
    var renderedImageLocalPath: String?
    var createdAt: Date = Date()
    var sortOrder: Int = 0           // Timeline order
}
```

**Relationship:** Trip 1:N TravelCard (cascade delete)

---

## 3. 핵심 서비스

### 3.1 PhotoLibraryService (PhotosKit)

```swift
final class PhotoLibraryService: ObservableObject {
    /// 권한 상태 확인
    var authorizationStatus: PHAuthorizationStatus { get }

    /// 권한 요청 (선택적 접근 지원)
    func requestAuthorization() async -> PHAuthorizationStatus

    /// 날짜/위치 기반 사진 그룹핑
    func fetchPhotos(for trip: Trip) async throws -> [PHAsset]

    /// PHAsset에서 CGImage 추출
    func fetchImage(for asset: PHAsset, targetSize: CGSize) async throws -> CGImage?

    /// 최근 사진 N장으로 Trip 커버 생성
    func createTripCover(from assets: [PHAsset]) async -> CGImage?

    /// PhotosKit에서 위치 기반 자동 Trip 추천
    func suggestTrips() async throws -> [TripSuggestion]
}

struct TripSuggestion {
    let name: String         // "도쿄"
    let startDate: Date
    let endDate: Date
    let photoCount: Int
    let locationName: String // Reverse geocoded
}
```

**권한 처리:**
1. `.limited` (선택적 접근) 허용 — 거부 시에도 일부 기능 작동
2. `.denied` → OnboardingView에서 재요유도 버튼
3. 앱 첫 실행 시 `.limited` 기본 요청 (`.addOnly` 아님)

### 3.2 CardRenderer (Core Graphics)

```swift
final class CardRenderer {
    /// 카드 렌더링 메인 메서드
    func render(
        photo: CGImage,
        text: String?,
        template: CardTemplateType,
        size: CGSize = CGSize(width: 1080, height: 1350)
    ) async throws -> UIImage

    /// PNG 내보내기
    func exportPNG(_ image: UIImage) throws -> URL

    /// 미리보기용 저해상도 이미지 (빠른 미리보기)
    func renderPreview(
        photo: CGImage,
        text: String?,
        template: CardTemplateType,
        size: CGSize = CGSize(width: 390, height: 488)
    ) async throws -> UIImage
}
```

**렌더링 파이프라인:**
```
[photo CGImage] → [template draw background] → [draw photo with aspect fill]
→ [optional overlay for text readability] → [draw text with font/config]
→ [draw watermark/branding if any] → [UIImage] → [PNG export]
```

**템플릿 규격:**

| 템플릿 | 크기 | 폰트 | 배경 | 오버레이 |
|--------|------|------|------|----------|
| 라이트 | 1080x1350 | Apple SD Gothic Neo 42 | 밝은 그라디언트 (#F5F0EB → #FFFFFF) | 없음 (텍스트 아래에 흰 반투명 박스) |
| 다크 | 1080x1350 | Apple SD Gothic Neo Light 38 | 어두운 (#1A1A2E → #16213E) | 사진 위에 rgba(0,0,0,0.6) |
| 미니멀 | 1080x1920 | SF Pro Rounded 36 | 흰 여백 + 사진 중앙 크롭 | 없음 |

**명도 대비 (WCAG AA):**
- 텍스트 컬러: 라이트=#1A1A1A, 다크=#F5F0EB, 미니멀=#1A1A1A
- 반투명 오버레이 alpha ≥ 0.6 필수

### 3.3 TripGroupingService (자동 그룹핑)

```swift
final class TripGroupingService {
    /// PhotosKit에서 위치+날짜 기반 자동 Trip 생성
    /// - Photos clustered by: same place (±30km) within ±7 days
    func autoGroupPhotos(from assets: [PHAsset]) -> [TripSuggestion]
}
```

**그룹핑 알고리즘 (PoC 단순화):**
1. PHAsset를 `creationDate` 기준으로 정렬
2. 날짜 갭 > 3일 → new Trip 분할
3. 동일 Trip 내에서 reverse geocoding으로 주요 장소명 추출
4. Trip 이름 = "{장소명} {yyyy.MM}"

**PoC에서는:** 사용자가 직접 Trip 생성 + PhotosKit에서 수동 사진 선택으로 우선 구현.
자동 그룹핑은 Phase 2.

---

## 4. 화면별 구현 상세

### 4.1 홈 (HomeView)

**참조:** `docs/mockups/01-home.html`

```
HomeView (SwiftUI)
├── NavigationStack
│   ├── .navigationTitle("내 여행") — Large Title
│   ├── ScrollView {
│   │   └── ForEach(trips) { trip in
│   │       TripListCard(trip: trip)
│   │           .onTapGesture → TripDetailView
│   │   }
│   │   └── EmptyStateView() — trips.isEmpty 시
│   }
│   └── .toolbar {
│       ToolbarItem(placement: .primaryAction) — "+" (Add Trip)
│   }
└── Sheet: AddTripSheet (Trip 이름 + 날짜 범위 입력)

TripListCard:
├── TripCoverImage — Phase 1: 그라디언트, Phase 2: 실제 대표사진
├── Trip name (18pt bold)
├── Date range (14pt, secondary)
└── CardCount badge ("📸 N장의 카드")

TabBar (Phase 1 — dummy tabs):
├── 여행 (active)
├── 지도 (disabled, "Phase 2 준비중" toast)
└── 설정 (opens Sheet)
```

**데이터 바인딩:** `@Query` for Trips (SwiftData) → `TripsViewModel`에서 정렬/필터링

### 4.2 여행 상세 (TripDetailView)

**참조:** `docs/mockups/02-trip-detail.html`

```
TripDetailView(trip: Trip)
├── Header: Trip name + duration ("2024.06 도쿄 · 6일")
├── ScrollView {
│   └── LazyVGrid(columns: 2) {
│       ForEach(cards, id: \.id) { card in
│           CardThumbnailView(card: card)
│               .onTapGesture → CardPreviewView
│       }
│   }
│   └── EmptyState: "아직 카드가 없어요" + "첫 카드 만들기" 버튼
│       → CreateCardView(trip: trip)
}
└── .toolbar {
    ToolbarItem — "카드 만들기" → CreateCardView(trip: trip)
}
```

**CardThumbnailView:** 2컬럼 그리드, aspect ratio 4:5, rounded corners 12

### 4.3 카드 생성 (CreateCardView)

**참조:** `docs/mockups/03-create-card.html` — 가장 복잡한 화면

```
CreateCardView(trip: Trip?)
├── Step 1: 사진 선택
│   ├── PhotosPicker (PhotosKit 기반 피커)
│   │   — single selection (MVP: 1장만)
│   │   — filtering: tri?.startDate ~ trip.endDate (있다면)
│   └── 선택된 사진 미리보기 (full width, aspect fill)
│
├── Step 2: 텍스트 입력
│   ├── TextField("여정에 한 줄을 남겨보세요")
│   ├── Share Extension에서 받은 텍스트가 있으면 미리 채움
│   └── 글자 수 제한: 200자 (counter 표시)
│
├── Step 3: 템플릿 선택
│   ├── Horizontal scroll: [라이트 | 다크 | 미니멀]
│   ├── 각 템플릿: 미리보기 썸네일 (실시간 preview)
│   └── 선택된 템플릿 테두리 강조
│
├── Step 4: 미리보기 + 저장
│   ├── 카드 프리뷰 (실제 렌더링 결과)
│   ├── "저장" 버튼 → Trip에 TravelCard 저장
│   └── "공유" → 표준 UIActivityViewController
│
└── 하단 진행 표시 (Step indicator: ●○○○ → ○●○○ → ○○●○ → ○○○●)
```

**State Management:** `@Observable` CreateCardViewModel
```swift
enum CreationStep: Int, CaseIterable {
    case selectPhoto, inputText, chooseTemplate, preview
}
```

### 4.4 카드 미리보기 (CardPreviewView)

**참조:** `docs/mockups/04-card-preview.html`

```
CardPreviewView(travelCard: TravelCard)
├── Full-screen image display — CardRenderer.render() 결과
├── Swipe up для card metadata (text, date, template name)
├── Bottom action bar:
│   ├── "공유하기" → UIActivityViewController
│   ├── "저장하기 (PNG)" → Photos.app or Files
│   └── "편집하기" → CreateCardView로 돌아가서 (pre-filled)
└── Swipe to navigate prev/next card in same Trip
```

---

## 5. Share Extension 구현

### 5.1 구성

```
ShareExtension/
├── Info.plist
│   ├── NSExtension:
│   │   └── NSExtensionAttributes:
│   │       ├── NSExtensionActivationRule:
│   │       │   OR (
│   │       │     NSExtensionActivationSupportsText = YES,
│   │       │     NSExtensionActivationSupportsWebURLWithMaxCount = 1,
│   │       │     NSExtensionActivationSupportsImageWithMaxCount = 1
│   │       │   )
│   │       └── NSExtensionPointIdentifier: com.apple.share-services
│   └── App Groups: group.dev.garibong.wandercard (for data sharing)
├── ShareViewController.swift — UINavigationController subclass
│   └── viewDidLoad → UIHostingController(rootView: ShareRootView())
├── ShareRootView.swift
│   └── ShareViewModel — handle shared items
└── ShareViewModel.swift
    ├── sharedText: String?
    ├── sharedURL: URL?
    ├── sharedImage: UIImage?
    ├── loadItems(from providers: [NSItemProvider])
    └── navigateToCardCreation() — deep link to main app
```

### 5.2 Share Extension → Main App 데이터 전달

App Groups 기반 공유 또는 URL Scheme 사용 (PoC에서는 URL Scheme로 단순화):

```swift
// Share Extension
UIApplication.shared.open(URL(string: "wandercard://share?text=\(encoded)")!)

// App (SceneDelegate / WanderCardApp)
.onOpenURL { url in
    // Parse URL, navigate to CreateCardView with shared data
}
```

**URL Scheme:** `wandercard://share?text=...&url=...`

---

## 6. 온보딩 (OnboardingView)

```
OnboardingView
├── Page 1: "여행 사진을 예쁜 카드로"
│   └── 일러스트 + "스크린샷 3장의 카드 예시"
├── Page 2: "공유 시트에서 쉽게"
│   └── "카카오맵 → 공유 → WanderCard" 스크린샷
├── Page 3: "사진 접근 권한 설명"
│   └── "여행 사진만 분석합니다. 원본 수정/업로드 없음."
│   └── "선택한 사진만 접근합니다" — ✅ 체크
└── "시작하기" 버튼 → PhotosKit 권한 요청
```

**권한 체인:**
```
Onboarding 완료 → PHPhotoLibrary.requestAuthorization(for: .readWrite)
→ .authorized/.limited → HomeView
→ .denied → "설정에서 권한을 변경해주세요" + 설정 앱 링크
```

---

## 7. 빌드 설정

### 7.1 Xcode Project (xcodegen)

```yaml
name: WanderCard
options:
  bundleIdPrefix: dev.garibong
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "16.0"
  generateEmptyDirectories: true

targets:
  WanderCard:
    type: application
    platform: iOS
    sources: [WanderCard]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: dev.garibong.wandercard
        MARKETING_VERSION: "0.1.0"
        CURRENT_PROJECT_VERSION: 1
        CODE_SIGN_IDENTITY: "-"
        CODE_SIGNING_REQUIRED: NO
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_NSPhotoLibraryUsageDescription: "여행 사진을 카드 이미지로 생성하기 위해 사진 라이브러리에 접근합니다."
        INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription: "생성된 카드를 사진 라이브러리에 저장합니다."
    dependencies: []

  ShareExtension:
    type: app-extension
    platform: iOS
    sources: [ShareExtension]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: dev.garibong.wandercard.share
        CODE_SIGN_IDENTITY: "-"
        CODE_SIGNING_REQUIRED: NO
    dependencies: []
```

### 7.2 빌드 확인 명령

```bash
# 프로젝트 생성
xcodegen generate

# 빌드 (시뮬레이터)
xcodebuild -scheme WanderCard \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# 단위 테스트
xcodebuild test -scheme WanderCard \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
```

### 7.3 필수 앱 설정 (Info.plist)

- `NSPhotoLibraryUsageDescription` — "여행 사진을 카드 이미지로 생성하기 위해 사진 라이브러리에 접근합니다."
- `NSPhotoLibraryAddUsageDescription` — "생성된 카드를 사진 라이브러리에 저장합니다."
- `LSApplicationQueriesSchemes` — ["kakao" (optional, Phase 2)]
- URL Types: `wandercard` (URL Scheme for Share Extension deep link)

---

## 8. PoC 범위 (MVP 구현 체크리스트)

### Phase 1 — 필수 구현

- [ ] Xcode 프로젝트 초기화 (`xcodegen generate`)
- [ ] SwiftData 모델: `Trip`, `TravelCard`
- [ ] **HomeView** — Trip 목록 (샘플 데이터 3개로 시작)
- [ ] **TripDetailView** — 카드 그리드 (empty state 포함)
- [ ] **CreateCardView** — 4단계 플로우
  - [ ] PhotosPicker 연동
  - [ ] 텍스트 입력 (200자 제한)
  - [ ] 템플릿 3종 선택 + 미리보기
  - [ ] 카드 저장 + 공유
- [ ] **CardRenderer** — Core Graphics 템플릿 3종
  - [ ] 라이트 (일기풍)
  - [ ] 다크 (감성풍)
  - [ ] 미니멀 (인스타용, 1080x1920)
- [ ] **CardPreviewView** — 전체 화면 미리보기 + 공유 시트
- [ ] **기본 온보딩** — 3페이지 + PhotosKit 권한 요청
- [ ] **Trip 생성/삭제** — AddTripSheet / Swipe to delete
- [ ] Sample images in Preview Content (개발용)

### Phase 1 — Share Extension (MVP)

- [ ] Share Extension Target 생성
- [ ] URL/Text/Image 수신 처리
- [ ] URL Scheme로 Main 앱에 데이터 전달
- [ ] CreateCardView에서 received text pre-fill

### Phase 1 — 제외 (Phase 2로 미룸)

- [ ] 자동 Trip 그룹핑 (PhotosKit 메타데이터 분석)
- [ ] MapKit 연동
- [ ] 템플릿 커스터마이징 (폰트/색상 변경)
- [ ] 카드 컬렉션/앨범 뷰
- [ ] Apple Watch 연동
- [ ] AI 기반 필터/보정

---

## 9. 독서잔디(Reading Garden)에서 재사용 가능한 패턴

| Reading Garden 패턴 | WanderCard 적용 |
|---|---|
| `@Model` SwiftData 엔티티 | 동일 패턴 — `Trip`, `TravelCard` |
| Card UI 컴포넌트 | 여행 카드 템플릿 UI 재구성 |
| iOS Share Sheet 연동 | 동일 — `UIActivityViewController` |
| Preview Content 샘플 데이터 | 동일 패턴 |
| Onboarding flow | 동일 — 권한 요청 전 설명 페이지 |
| Localization (en/ko) | 동일 — `Localizable.xcstrings` |
| xcodegen 빌드 시스템 | 동일 설정 구조 |

---

## 10. 개발 순서 (추천)

```
1. [Eli] xcodegen project 생성 + SwiftData 모델 정의
2. [Eli] HomeView + TripDetailView (샘플 데이터)
3. [Eli] CardRenderer Core Graphics 템플릿 3종
4. [Eli] CreateCardView (사진 선택 + 텍스트 + 템플릿)
5. [Eli] CardPreviewView + Save/Share
6. [Eli] Onboarding + PhotosKit 권한
7. [Eli] Share Extension
8. [Eli] Sample images + Localization
```

**예상 기간:** 2-3일 (독서잔디 파이프라인 재사용 시)

---

*구현 명세서 v0.1 — ACP(Codex) 세션에서 구현 시 기준으로 사용*
