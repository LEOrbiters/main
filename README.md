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
numpy==1.24.0 
sgp4==2.22 
python-dateutil==2.8.2
request
traffic

## Install required packages
python3 -m pip install -r requirements.txt
OR npm run require <!-- this is for python pip>

## anaconda setup
1. download anaconda for operating system (Linux, Windows, Mac,...)
2. open anaconda promt or .sh bash shell
3. conda create -n traffic -c conda-forge python=3.10 traffic
4. conda activate traffic <!-- repeat as many times as traffic needs to be setup>
5.(optional) 
### -n option is followed by the name of the environment
conda update -n traffic -c conda-forge traffic

## Run sampling test file (keep editing)
Python: python "LEO Backend Test.py" 
Python3: python3 "LEO Backend Test.py"

## api execution (edit and update package.json with implemented backend api)
npm run server

Default: npm install (nodejs MUST 설치 필수) then npm run dev
