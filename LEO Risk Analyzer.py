# Final version with SME-tuned parameters

import numpy as np
from sgp4.api import Satrec, WGS72
from sgp4.api import jday
import datetime

# 0. Constants and Parameters

TLE_FILE = "spacetrack_leo_3le.txt"

# Incheon FIR Boundaries 
FIR_LAT_MIN = 35.5
FIR_LAT_MAX = 38.5
FIR_LON_MIN = 125.0
FIR_LON_MAX = 127.5

# Tuning and Policy Parameters
D0_VAL = 25.0       # Reference distance: Confirmed by SME
DELTA_T_VAL = 60.0  
TAU_VAL = 600.0     # Time decay constant (10 minutes per SME)
DSE_VAL = 1.0       # Debris/Environment Index (Neutral value per SME)
W_ODPO_H_VAL = 0.9  # 
W_OPS_VAL = 1.0     # 


# 1. Helper Functions

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


# 2. TLE Loading Function

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

# 3. Core Analysis Function

def run_full_risk_analysis(satellites):
    """
    Propagates satellites for the current time (epoch) and performs
    conjunction analysis, returning results as a list of Python-native dicts.
    """
    now = datetime.datetime.utcnow()
    sat_positions = []
    conjunction_events = []

    # 3. Propagate and Filter by Incheon FIR
    for sat in satellites:
        s = Satrec.twoline2rv(sat['line1'], sat['line2'])
        jd, fr = jday(now.year, now.month, now.day, now.hour, now.minute, now.second)
        e, r, v = s.sgp4(jd, fr)

        if e == 0:
            lat = np.degrees(np.arcsin(r[2] / np.linalg.norm(r)))
            lon = np.degrees(np.arctan2(r[1], r[0]))

            if is_in_fir(lat, lon):
                sat_positions.append({
                    'name': sat['name'],
                    'lat': lat,
                    'lon': lon,
                    'r': r,
                    'v': v
                })

    # 4. Conjunction Analysis (Risk Score Logic)
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

            # Check closeness
            if d_val < 500:
                
                risk_score = calculate_R_final_revised(
                    d=d_val, d0=D0_VAL, delta_t=DELTA_T_VAL, tau=TAU_VAL, # ew TAU_VAL
                    v_rel=v_rel_val, DSE=DSE_VAL, W_odpo_h=W_ODPO_H_VAL, W_ops=W_OPS_VAL # new DSE_VAL
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

    # This returns the data to the Flask API caller (server.py)
    return conjunction_events