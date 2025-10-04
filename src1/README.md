# LEO Orbiters - Flutter Web

LEO 위성 충돌 & 우주 파편 위험 시각화 대시보드

## Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Node.js (for the backend server)

## Project Structure

```
main/
├── lib/
│   ├── main.dart              # Main Flutter application
│   ├── models/
│   │   └── alert.dart         # Data models
│   ├── services/
│   │   └── api_service.dart   # API service for backend communication
│   └── widgets/
│       ├── left_panel.dart    # Left sidebar panel
│       └── map_view.dart      # Map view with markers
├── web/
│   ├── index.html
│   └── manifest.json
├── pubspec.yaml               # Flutter dependencies
├── analysis_options.yaml      # Dart linter configuration
└── server.js                  # Express backend server
```

## Installation

### Install Flutter Dependencies

```bash
cd src1
flutter pub get
```

### Install Server Dependencies (from project root)

```bash
npm install
```

## Development

### Run Both Server and Client

```bash
npm run dev
```

This runs:
- Express server on `http://localhost:60579`
- Flutter web app on Chrome

### Run Server Only

```bash
npm run server
```

### Run Flutter Client Only

```bash
npm run client
```

Or directly:

```bash
cd main
flutter run -d chrome
```

## Build

### Build Flutter Web App

```bash
npm run build
```

Or directly:

```bash
cd main
flutter build web
```

The built files will be in `main/build/web/`

## API Endpoints

- `GET /api/alerts` - Get current alerts
- `GET /api/alerts/:date` - Get alerts for specific date

## Features

- Real-time satellite collision alerts
- Interactive map with OpenStreetMap integration
- FIR region filtering (Incheon, Fukuoka, Pyongyang)
- Date navigation for historical data
- Risk-based color coding
- Auto-refresh every 30 seconds