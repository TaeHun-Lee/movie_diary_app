# Movie Diary - Frontend Application

Flutter를 기반으로 개발된 영화 다이어리 모바일 애플리케이션입니다. 사용자 인증을 통해 영화를 검색하고, 다른 사용자들의 다이어리 피드를 볼 수 있으며, 자신만의 영화 리뷰를 작성/관리할 수 있습니다.

## 📱 프로젝트 구조 및 주요 사용 기술

- **Framework**: Flutter (Dart)
- **State Management**:
  - `Provider`: 인증 상태(Auth) 등 전역 상태 관리
  - `Riverpod`: 게시글 목록 상태 관리, 메모리 캐시 최적화
- **네트워크 / API**: `http` 패키지 사용, `api_service` 레이어에서 JWT 토큰 인증과 에러 인터셉트 수행
- **UI 디자인**: 자체 디자인 시스템 (Stitch Design / The Ethereal Archive) 적용 (라이트 톤, Neuromorphic 스타일 중심)
- **주요 외부 패키지**: `flutter_dotenv`, `shared_preferences`, `connectivity_plus`, `image_picker`

## ⚙️ 사전 요구사항 (Prerequisites)

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (안정 버전 권장)
- Android Studio 또는 Xcode (에뮬레이터 및 빌드 환경)
- 백엔드(NestJS) 서버 (본 앱은 구동 중인 백엔드 API에 의존합니다.)

## 🚀 설정 및 실행 방법 (How to Run)

### 1. 패키지 설치
터미널에서 아래 명령어를 실행하여 필요한 의존성을 설치합니다.
```bash
flutter pub get
```

### 2. 환경 변수 설정
프로젝트 최상단에 있는 `.env.example` 파일을 복사하여 `.env` 파일을 생성합니다. (만약 `.env.example`이 없다면 아래 예시를 참고하여 `.env` 파일을 만드세요.)
```bash
cp .env.example .env
```

`.env` 파일 내용 예시 (백엔드가 로컬 `http://localhost:3000`에서 실행 중인 경우):
```env
# 에뮬레이터 환경 (Android: http://10.0.2.2:3000, iOS: http://localhost:3000)
API_BASE_URL=http://localhost:3000/api/v1
```

### 3. 프로젝트 실행
에뮬레이터나 실제 디바이스를 연결한 뒤 다음 명령어를 통해 앱을 실행합니다.
```bash
flutter run
```

## 🧪 테스트 실행 (Testing)
유닛 및 위젯 테스트가 작성되어 있습니다.
```bash
flutter test
```

## 📁 주요 디렉토리 구조 (lib/)
- `/constants.dart`: 전체 앱에서 사용되는 테마, 색상, 디자인 시스템 정의
- `/component/`: 공통으로 사용되는 UI 위젯 모음 (버튼, 카드 등)
- `/screens/`: 각 화면(Page) UI 위젯
- `/services/`: 백엔드 통신을 담당하는 API 서비스 (`api_service.dart` 등)
- `/providers/`: `Provider` 기반 상태 관리
- `/repositories/`: 데이터 레포지토리 패턴 클래스
