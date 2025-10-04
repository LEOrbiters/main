# LEO Satellite Backend Test

import numpy as np
from sgp4.api import Satrec, WGS72
from sgp4.api import jday
import datetime
import csv

def calculate_R_final_revised(d, d0, delta_t, tau, v_rel, DSE, W_odpo_h, W_ops):
    """
    Args:
        d (float): Distance variable d.
        d0 (float): Reference distance variable d0.
        delta_t (float): Time increment Δt.
        tau (float): Time constant τ.
        v_rel (float): Relative velocity v_rel.
        DSE (float): DSE variable.
        W_odpo_h (float): W_odpo(h) variable (modified term).
        W_ops (float): W_ops variable.

    Returns:
        float: Calculated final value R_final.
    """

    # 1. First term: (exp[-(d/d0)^2])^0.5
    term1 = np.exp(-(d / d0)**2)**0.5

    # 2. Second term: (exp[-Δt/τ])^0.3
    term2 = np.exp(-delta_t / tau)**0.3

    # 3. Third term: clip(v_rel/15, 0.1)^0.2
    # Calculate v_rel/15, clip to 0.1 if smaller (no upper limit)
    clip_value = np.clip(v_rel / 15, 0.1, None)
    term3 = clip_value**0.2

    # 4. Fourth term: exp[-max(0, DSE-2)/3]
    max_value = np.maximum(0, DSE - 2)
    term4 = np.exp(-max_value / 3)

    # 5. Fifth term: W_odpo(h) (modified term)
    term5 = W_odpo_h

    # 6. Sixth term: W_ops
    term6 = W_ops

    # Calculate final R_final
    R_final = term1 * term2 * term3 * term4 * term5 * term6

    return R_final

# Risk Category

def assign_risk_category(risk_score):
    # Not yet final
    if risk_score > 0.1:
        return "Danger"
    elif risk_score > 0.001:
        return "Attention"
    else:
        return "Safe"

# 1. Load TLE data

tle_file = "spacetrack_leo_3le.txt"  # TLE file path

satellites = []

with open(tle_file, "r") as f:
    lines = f.readlines()
    for i in range(0, len(lines), 3):
        name = lines[i].strip()
        line1 = lines[i+1].strip()
        line2 = lines[i+2].strip()
        satellites.append({'name': name, 'line1': line1, 'line2': line2})

print(f"Loaded {len(satellites)} satellites from TLE data")


# 2. Incheon FIR

FIR_LAT_MIN = 35.5
FIR_LAT_MAX = 38.5
FIR_LON_MIN = 125.0
FIR_LON_MAX = 127.5


# 3. Propagate satellites and filter by Incheon FIR

def is_in_fir(lat, lon):
    return FIR_LAT_MIN <= lat <= FIR_LAT_MAX and FIR_LON_MIN <= lon <= FIR_LON_MAX

now = datetime.datetime.utcnow()
sat_positions = []

for sat in satellites:
    s = Satrec.twoline2rv(sat['line1'], sat['line2'])
    jd, fr = jday(now.year, now.month, now.day, now.hour, now.minute, now.second)
    e, r, v = s.sgp4(jd, fr)  # r = position in km, v = velocity in km/s

    if e == 0:
        lat = np.degrees(np.arcsin(r[2] / np.linalg.norm(r)))   # simple lat calculation
        lon = np.degrees(np.arctan2(r[1], r[0]))               # simple lon calculation

    if is_in_fir(lat, lon):
        sat_positions.append({
            'name': sat['name'],
            'lat': lat,
            'lon': lon,
            'alt': np.linalg.norm(r),
            'r': r, # Store position vector (in km)
            'v': v  # Store velocity vector (in km/s)
    })

print(f"Satellites near Incheon FIR: {len(sat_positions)}")
for sat in sat_positions:
    print(sat)


# 4. Conjunction Analysis (The NEW Risk Score Logic)

print("\n--- Starting Conjunction Analysis ---")
conjunction_events = []

# WARNING: These parameters are INITIAL DEFAULTS/PLACEHOLDERS. 
# The SME will tune d0 and tau later based on output results.

d0_val = 10.0      # Tuning Constant: Reference distance (Initial default)
delta_t_val = 60.0 # Policy Constant: Sample time interval (using max 60 sec per SME)
tau_val = 300.0    # Tuning Constant: Time decay constant (Initial default)

# External/Policy Variables - Using placeholders until external data feeds are integrated.
DSE_val = 5.0      # External: Debris/Environment Index (Placeholder)
W_odpo_h_val = 0.9 # External: ODPO Weight (Placeholder)
W_ops_val = 1.0    # External: Operational Weight (Placeholder)

# Create pairs of satellites to compare (nested loop)
num_sats = len(sat_positions)
for i in range(num_sats):
    for j in range(i + 1, num_sats): # Start j from i+1 to avoid duplicates and self-comparison
        sat1 = sat_positions[i]
        sat2 = sat_positions[j]

        # Calculate distance 'd' between the two satellites
        r1 = np.array(sat1['r'])
        r2 = np.array(sat2['r'])
        d_val = np.linalg.norm(r1 - r2) # This is the distance in km

        # Calculate relative velocity 'v_rel'
        v1 = np.array(sat1['v'])
        v2 = np.array(sat2['v'])
        v_rel_val = np.linalg.norm(v1 - v2) # Relative velocity in km/s
        
        # We only care about objects that are reasonably close
        if d_val < 500: # Example threshold: only calculate risk for sats closer than 50 km
            
            risk_score = calculate_R_final_revised(
                d=d_val,
                d0=d0_val,
                delta_t=delta_t_val,
                tau=tau_val,
                v_rel=v_rel_val,
                DSE=DSE_val,
                W_odpo_h=W_odpo_h_val,
                W_ops=W_ops_val
            )
            # Determine the risk category
            risk_category = assign_risk_category(risk_score)
            
            # Store the result if the risk is significant
            if risk_score > 0.0000001: # Set a very low threshold to keep all calculated events
                conjunction_events.append({
                'satellite1': sat1['name'],
                'satellite2': sat2['name'],
                'risk_score': risk_score,
                'risk_category': risk_category,  # NEW KEY-VALUE PAIR
                'distance_km': d_val,
                'relative_velocity_km_s': v_rel_val
            })


print(f"Found {len(conjunction_events)} significant collision events.")
for event in conjunction_events:
    print(event)


# 5. Save to CSV tables

# Satellites Table
with open("satellites.csv", "w", newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['satellite_id','name']) 
    writer.writeheader()
    for i, sat in enumerate(sat_positions, start=1):
        writer.writerow({
            'satellite_id': i,
            'name': sat['name']
        })

# Trajectories Table 
with open("trajectories.csv", "w", newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['trajectory_id','satellite_id','timestamp','lat','lon','alt'])
    writer.writeheader()
    for i, sat in enumerate(sat_positions, start=1):
        writer.writerow({
            'trajectory_id': i,
            'satellite_id': i,
            'timestamp': now.isoformat(),
            'lat': sat['lat'],
            'lon': sat['lon'],
            'alt': sat['alt']
        })

# Collisions Table (NEW)
with open("collisions.csv", "w", newline='') as f:
    fieldnames = ['collision_id', 
                  'satellite1', 'satellite2', 'risk_score', 'risk_category', 'distance_km', 'relative_velocity_km_s']
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader() # 🟢 Added to ensure the header is written

    for i, event in enumerate(conjunction_events, start=1):
        writer.writerow({
            'collision_id': i,
            'satellite1': event['satellite1'],
            'satellite2': event['satellite2'],
            'risk_score': event['risk_score'],
            'risk_category': event['risk_category'],
            'distance_km': event['distance_km'],
            'relative_velocity_km_s': event['relative_velocity_km_s']
        })