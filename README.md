# main
FIR 공역 기반 LEO 위성 충돌 조기예보 및 시각화 시스템

FIR-Based LEO Satellite Collision Early-Warning and Visualization System

# 클라이언트 사이드 Flutter 실행 

```bash
cd src1
flutter pub get
```
Google Map API key: src1/assets/.env REQUIRED

# 서버 사이드 Python Flask 실행:
## Add to requirements.txt (keep editing)
numpy>=1.24.0 
sgp4>=2.22 
python-dateutil>=2.8.2

## Install required packages
python3 -m pip install -r requirements.txt

## Run sampling test file (keep editing)
Python: python "LEO Backend Test.py" 
Python3: python3 "LEO Backend Test.py"

Default: npm install (nodejs MUST 설치 필수) then npm run dev
