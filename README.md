# main
LEO 위성 충돌 &amp; 우주 파편 위험 시각화 대시보드

Default: npm install (nodejs MUST 설치 필수) then npm run dev

# Client Flutter npm
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

# Server: Python Flask 
## Add to requirements.txt (keep editing)
numpy>=1.24.0 sgp4>=2.22 python-dateutil>=2.8.2

## Install required packages
python3 -m pip install -r requirements.txt

## Run sampling test file (please add)
Python: python "LEO Backend Test.py" 
Python3: python3 "LEO Backend Test.py"