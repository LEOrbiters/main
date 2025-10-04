# risk_analyzer.py (FINAL VERSION)

import numpy as np
from sgp4.api import Satrec, WGS72
from sgp4.api import jday
import requests
import os
from datetime import datetime, UTC
from marshmallow import Schema, fields

# 0. Constants and Parameters (SME-Tuned)

TLE_FILE = "spacetrack_leo_3le.txt"
R_EARTH = 6371.0 # Earth Radius in km, used for altitude calculation

# Incheon FIR Boundaries 
FIR_LAT_MIN = 35.5
FIR_LAT_MAX = 38.5
FIR_LON_MIN = 125.0
FIR_LON_MAX = 127.5

# Tuning and Policy Parameters
D0_VAL = 25.0       # Reference distance (km)
DELTA_T_VAL = 60.0  
TAU_VAL = 600.0     # Time decay constant (10 minutes per SME)
DSE_VAL = 1.0       # Debris/Environment Index (Neutral value per SME)


# 1. Dynamic Weight Calculation Functions (API Simulators)

def get_W_odpo_h(altitude_km):
    """
    Simulates fetching the ODPO Debris Persistence Weight based on altitude.
    (Replace with actual API call later)
    """
    ODPO_API_URL = "https://odpo.nasa.gov/api/weights" 
    API_KEY = os.getenv('ODPO_API_KEY')
    payload = {"api_key": API_KEY, "altitude_km": altitude_km}
    try:
        response = requests.get(ODPO_API_URL, params=payload, timeout=5)
        response.raise_for_status() 
        # Actual implementation: return response.json().get("weight", 0.9)
        return 0.9 
    except requests.exceptions.RequestException as e:
        print(f"ODPO API call failed: {e}")
        return 0.9 


def get_W_ops(lat, lon, analysis_time):
    """
    Simulates fetching the Operational Influence Weight (e.g., cloud cover) via EarthData API.
    (Replace with actual API call later)
    """
    EARTHDATA_API_URL = "https://earthdata.nasa.gov/api/fir/cloud-cover"
    API_TOKEN = os.getenv('EARTHDATA_API_TOKEN')
    time_str = analysis_time.isoformat()
    payload = {"token": API_TOKEN, "lat": lat, "lon": lon, "time": time_str}

    try:
        response = requests.get(EARTHDATA_API_URL, params=payload, timeout=5)
        response.raise_for_status()
        # Actual implementation: return response.json().get("cloud_weight", 1.0)
        return 1.0 
    except requests.exceptions.RequestException as e:
        print(f"EarthData API call failed: {e}")
        return 1.0


# 2. Marshmallow Schemas for API Documentation

class ConjunctionEventSchema(Schema):
    """Defines the structure of a single conjunction event in the API response."""
    satellite1 = fields.Str(
        required=True, 
        metadata={"description": "Name of the first satellite."}
    )
    satellite2 = fields.Str(
        required=True, 
        metadata={"description": "Name of the second satellite."}
    )
    risk_score = fields.Float(
        required=True, 
        metadata={"description": "Calculated final risk score (R_final)."}
    )
    risk_category = fields.Str(
        required=True, 
        metadata={"description": "Risk level (Safe, Attention, Danger)."}
    )
    distance_km = fields.Float(
        required=True, 
        metadata={"description": "Minimum distance between satellites in km."}
    )
    relative_velocity_km_s = fields.Float(
        required=True, 
        metadata={"description": "Relative velocity in km/s."}
    )

class RiskEventsResponseSchema(Schema):
    """Defines the overall structure of the /api/risk-events response."""
    timestamp = fields.Str(
        required=True, 
        metadata={"description": "UTC time of the analysis."}
    )
    events = fields.List(
        fields.Nested(ConjunctionEventSchema), 
        required=True, 
        metadata={"description": "List of all significant conjunction events."}
    )

# 3. Core Helper Functions

def calculate_R_final_revised(d, d0, delta_t, tau, v_rel, DSE, W_odpo_h, W_ops):
    """Calculates the final risk score R_final."""
    term1 = np.exp(-(d / d0)**2)**0.5
    term2 = np.exp(-delta_t / tau)**0.3
    clip_value = np.clip(v_rel / 15, 0.1, None)
    term3 = clip_value**0.2
    max_value = np.maximum(0, DSE - 2)
    term4 = np.exp(-max_value / 3)
    term5 = W_odpo_h
    term6 = W_ops
    R_final = term1 * term2 * term3 * term4 * term5 * term6
    return R_final

def assign_risk_category(risk_score):
    """Assigns the risk category based on the score (Thresholds unchanged)."""
    if risk_score > 0.1:
        return "Danger! Big risk of a collision."
    elif risk_score > 0.001:
        return "Attention! There is a risk for collision."
    else:
        return "Safe! There is no risk for a collision."

def is_in_fir(lat, lon):
    """Checks if coordinates are within the Incheon FIR box."""
    return FIR_LAT_MIN <= lat <= FIR_LAT_MAX and FIR_LON_MIN <= lon <= FIR_LON_MAX


# 4. TLE Loading Function

def load_tle_data(tle_file_path=TLE_FILE):
    """Loads all TLE data into a list of dictionaries."""
    satellites = []
    try:
        with open(tle_file_path, "r") as f:
            lines = f.readlines()
            for i in range(0, len(lines), 3):
                name = lines[i].strip()
                line1 = lines[i+1].strip()
                line2 = lines[i+2].strip()
                satellites.append({'name': name, 'line1': line1, 'line2': line2})
        return satellites
    except FileNotFoundError:
        print(f"Error: TLE file not found at {tle_file_path}") 
        return []

# 5. Core Analysis Function (Epoch and Dynamic Weights Implemented)

def run_full_risk_analysis(satellites, analysis_time=None):
    """
    Propagates satellites for the given analysis_time (epoch) and performs
    conjunction analysis, returning results as a list of Python-native dicts.
    """
    # Use current UTC time if no time is provided
    if analysis_time is None:
        analysis_time = datetime.now(UTC)
        
    sat_positions = []
    conjunction_events = []

    # 5.1 Propagate and Filter Incheon FIR
    for sat in satellites:
        s = Satrec.twoline2rv(sat['line1'], sat['line2'])
        
        # Propagate using the provided analysis_time
        jd, fr = jday(analysis_time.year, analysis_time.month, analysis_time.day, 
                      analysis_time.hour, analysis_time.minute, analysis_time.second)
        e, r, v = s.sgp4(jd, fr)

        if e == 0:
            lat = np.degrees(np.arcsin(r[2] / np.linalg.norm(r)))
            lon = np.degrees(np.arctan2(r[1], r[0]))

            if is_in_fir(lat, lon):
                sat_positions.append({
                    'name': sat['name'], 'lat': lat, 'lon': lon, 'r': r, 'v': v
                })

    # 5.2 Conjunction Analysis (Risk Score Logic)
    num_sats = len(sat_positions)
    for i in range(num_sats):
        for j in range(i + 1, num_sats):
            sat1 = sat_positions[i]
            sat2 = sat_positions[j]

            r1 = np.array(sat1['r'])
            r2 = np.array(sat2['r'])
            d_val = np.linalg.norm(r1 - r2)

            v1 = np.array(sat1['v'])
            v2 = np.array(sat2['v'])
            v_rel_val = np.linalg.norm(v1 - v2)

            # Check closeness (within 500km)
            if d_val < 500:
                
                # Calculate Altitude (distance from Earth's center minus Earth's radius)
                alt1_km = np.linalg.norm(r1) - R_EARTH
                
                # Call Dynamic Weight Functions
                W_odpo_h_val = get_W_odpo_h(alt1_km)
                W_ops_val = get_W_ops(sat1['lat'], sat1['lon'], analysis_time)
                
                risk_score = calculate_R_final_revised(
                    d=d_val, d0=D0_VAL, delta_t=DELTA_T_VAL, tau=TAU_VAL,
                    v_rel=v_rel_val, DSE=DSE_VAL, W_odpo_h=W_odpo_h_val, W_ops=W_ops_val
                )
                risk_category = assign_risk_category(risk_score)
                
                # Store if the risk is significant
                if risk_score > 0.0000001:
                    conjunction_events.append({
                        'satellite1': sat1['name'],
                        'satellite2': sat2['name'],
                        'risk_score': float(risk_score),
                        'risk_category': risk_category, 
                        'distance_km': float(d_val),
                        'relative_velocity_km_s': float(v_rel_val)
                    })

    return conjunction_events