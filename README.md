# FIR-Based LEO Satellite Collision Early-Warning and Visualization System

LEO 위성 충돌 & 우주 쓰레기 위험 시각화 대시보드

FIR 공역 기반 LEO 위성 충돌 조기예보 및 시각화 시스템

---

# Backend (Python Flask + Risk Analysis) Setup:

## 1. Add to requirements.txt (keep editing)
numpy>=1.24.0
sgp4>=2.22
python-dateutil>=2.8.2

## 2. Install required packages
python3 -m pip install -r requirements.txt

## 3. Run the Risk Sampling Test File
Python: python "LEO Backend Test.py"
Python3: python3 "LEO Backend Test.py"

## 4. Run the Python Flask Server
(Instructions to run server.py go here after integration)

---

# Client Side (Flutter) Setup:

1.  **Install Node.js** (Required for default client setup)
2.  **Install Flutter/Dart SDK**
3.  **Client Dependencies**
    ```bash
    cd src1
    flutter pub get
    ```
4.  **Run Development Server**
    ```bash
    npm install
    npm run dev
    ```