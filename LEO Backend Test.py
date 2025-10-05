# LEO Satellite Backend Test

import numpy as np
from sgp4.api import Satrec, WGS72
from sgp4.api import jday
import datetime
import csv


# 1. Load TLE data

tle_file = "spacetrack_leo_3le.txt"  # My TLE file path

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
                'alt': np.linalg.norm(r)
            })

print(f"Satellites near Incheon FIR: {len(sat_positions)}")
for sat in sat_positions:
    print(sat)


# 4. Simple Risk Score (Demo)

# I'll assign random risk scores for demonstration purposes
for sat in sat_positions:
    sat['risk_score'] = np.random.rand()  # random value 0-1
    if sat['risk_score'] < 0.3:
        sat['risk_level'] = "safe"
    elif sat['risk_score'] < 0.7:
        sat['risk_level'] = "caution"
    else:
        sat['risk_level'] = "danger"


# 5. Save to CSV tables (Similar to ERD)

# Satellites Table
with open("satellites.csv", "w", newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['satellite_id','name','risk_score','risk_level'])
    writer.writeheader()
    for i, sat in enumerate(sat_positions, start=1):
        writer.writerow({
            'satellite_id': i,
            'name': sat['name'],
            'risk_score': sat['risk_score'],
            'risk_level': sat['risk_level']
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

print("Data saved to CSV files (satellites.csv, trajectories.csv)")
