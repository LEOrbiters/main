# risk_analyzer.py - FINAL, API-BASED, FAIL-FAST VERSION

# 1. Imports and Setup
from sgp4.api import WGS72, Satrec, jday 
from datetime import datetime, timedelta, UTC
import math
import os
import requests
import json
from dotenv import load_dotenv

# 🚀 REQUIRED IMPORT for stable NASA access
import earthaccess 

from marshmallow import Schema, fields 

load_dotenv()

# --- FIXED: API Key Status Check (Using Basic Auth requirements) ---
_EARTHDATA_USERNAME = os.getenv("EARTHDATA_USERNAME", "").strip()
_EARTHDATA_PASSWORD = os.getenv("EARTHDATA_PASSWORD", "").strip() 
_ODPO_KEY = os.getenv("ODPO_API_KEY", "").strip() 

# CHECK LOGIC: If EITHER username or password is not set, we use the default W_ops=1.0.
_EARTHDATA_PLACEHOLDER = not _EARTHDATA_USERNAME or not _EARTHDATA_PASSWORD
_ODPO_PLACEHOLDER = os.getenv("ODPO_API_URL") is None 

# ONLY PRINT THESE WARNINGS ONCE AT STARTUP
if _EARTHDATA_PLACEHOLDER:
    print("[!] WARNING (One-Time): EARTHDATA_USERNAME and/or EARTHDATA_PASSWORD not set. Using safe default W_ops=1.0.")

if _ODPO_PLACEHOLDER:
    print("[!] WARNING (One-Time): ODPO/ORDEM API is restricted. Using altitude-based simulation for W_odpo_h.")
# -----------------------------------------------------------


# --- Geographical Definitions ---
SATELLITE_OWNERS = {
    'STARLINK': 'USA', 'ONEWEB': 'UK', 'IRIDIUM': 'USA', 'GLOBALSTAR': 'USA',
    'BEIDOU': 'CHN', 'QZS': 'JPN'
}

FIR_BOUNDARIES = {
    'INCHEON_FIR_RKRR': {'name': 'Incheon (South Korea)', 'country': 'KR', 'lat_min': 35, 'lat_max': 38, 'lon_min': 124, 'lon_max': 130},
    'FUKUOKA_FIR_RJJJ': {'name': 'Fukuoka (Japan)', 'country': 'JP', 'lat_min': 32, 'lat_max': 35, 'lon_min': 128, 'lon_max': 132},
    'PYONGYANG_FIR_ZYYY': {'name': 'Pyongyang (North Korea)', 'country': 'KP', 'lat_min': 38, 'lat_max': 42, 'lon_min': 124, 'lon_max': 130},
    'SHANGHAI_FIR_ZSHA': {'name': 'Shanghai (China)', 'country': 'CN', 'lat_min': 25, 'lat_max': 35, 'lon_min': 118, 'lon_max': 122},
    'SANYA_FIR_ZJSA': {'name': 'Sanya (China)', 'country': 'CN', 'lat_min': 15, 'lat_max': 25, 'lon_min': 105, 'lon_max': 115},
}

def find_fir_by_location(lat, lon):
    OPENAIP_API_KEY = os.getenv("OPENAIP_API_KEY"); OPENAIP_API_URL = os.getenv("OPENAIP_API_URL", "https://api.openaip.net/api/airspaces") 
    if OPENAIP_API_KEY:
        try:
            # Placeholder for OpenAIP API search logic
            pass
        except Exception: pass
    for bounds in FIR_BOUNDARIES.values():
        if (bounds['lat_min'] <= lat <= bounds['lat_max'] and bounds['lon_min'] <= lon <= bounds['lon_max']):
            return bounds['name']
    return "Open Ocean/Other"

def get_satellite_country(satellite_name):
    for prefix, country in SATELLITE_OWNERS.items():
        if satellite_name.upper().startswith(prefix.upper()): return country
    return "Unknown"

# --- 2. Marshmallow Schemas (Omitted for brevity) ---
class ConjunctionEventSchema(Schema):
    satellite1 = fields.Str(required=True); satellite2 = fields.Str(required=True)
    risk_score = fields.Float(required=True); distance_km = fields.Float(required=True)
    relative_velocity_km_s = fields.Float(required=True); fir = fields.Str(required=True)
    country_of_origin_1 = fields.Str(required=True); country_of_origin_2 = fields.Str(required=True)

class RiskEventsResponseSchema(Schema):
    timestamp = fields.Str(required=True); events = fields.List(fields.Nested(ConjunctionEventSchema), required=True)


# --- 3. Dynamic Weight Calculation (API Integration) ---

def fetch_operational_weight(lat, lon, analysis_time):
    """
    (W_ops) Fetches the Operational Influence Weight (Cloud Cover) using earthaccess.
    **CRITICAL: Added aggressive timeout to prevent hang.** Returns 1.0 on failure.
    """
    global _earthdata_session
    API_URL = "https://cmr.earthdata.nasa.gov/search/granules.json"
    
    if _EARTHDATA_PLACEHOLDER: return 1.0
    
    # 1. AUTHENTICATE AND GET SESSION (Only done once)
    if _earthdata_session is None:
        try:
            auth = earthaccess.login(strategy="env") 
            _earthdata_session = auth.get_requests_https_session()
        except Exception:
            # Fallback to 1.0 if AUTH fails
            return 1.0
        
    try:
        # 2. PERFORM REQUEST using the authenticated session
        CLOUD_PRODUCT_ID = "C1239634898-GESDISC" # Placeholder ID for a real cloud product
        
        params = {
            "bounding_box": f"{lon-0.1},{lat-0.1},{lon+0.1},{lat+0.1}", 
            "temporal": f"{analysis_time.isoformat()}Z", 
            "collection-concept-id": CLOUD_PRODUCT_ID, 
            "page_size": 1,
            "sort_key": "-start_date" 
        }
        
        # 🚨 AGGRESSIVE TIMEOUT: Must fail in 0.5 seconds if connection is bad
        response = _earthdata_session.get(API_URL, params=params, timeout=0.5) 
        response.raise_for_status() 
        
        data = response.json()
        entries = data.get("feed", {}).get("entry", [])
        
        if not entries: return 1.0

        # ... Cloud Cover calculation logic
        granule_entry = entries[0]
        CLOUD_COVER_KEY = "Cloud_Fraction" 
        cloud_cover_percent = granule_entry.get(CLOUD_COVER_KEY, 0.0) * 100 
        
        W_ops = 1.0 - (cloud_cover_percent / 200.0)
        
        return max(0.5, min(1.0, W_ops)) 

    except Exception:
        # Fails silently and uses the default 1.0
        return 1.0

def fetch_odpo_persistence_weight(alt):
    """
    (W_space) Fetches the MOCAT/Space Weather Influence Weight based on NOAA F10.7 Solar Flux.
    **CRITICAL: Added aggressive timeout to prevent hang.** Returns a default 1.0 on failure.
    """
    NOAA_API_URL = "https://services.swpc.noaa.gov/json/f107_latest.json"
    
    try:
        # 🚨 AGGRESSIVE TIMEOUT: Must fail in 0.5 seconds if connection is bad
        response = requests.get(NOAA_API_URL, timeout=0.5)
        response.raise_for_status()
        data = response.json()
        
        f107_value = float(data[0].get("observed_f107", 100.0))
        
        # 2. Convert F10.7 to a weight 
        F107_MIN = 70.0  
        F107_MAX = 200.0 
        
        normalized_f107 = (f107_value - F107_MIN) / (F107_MAX - F107_MIN)
        normalized_f107 = max(0.0, min(1.0, normalized_f107))
        
        W_space = 1.0 - (normalized_f107 * 0.5) 
        
        return W_space 
        
    except Exception:
        # If the NOAA API fails, default to the max risk weight (1.0)
        return 1.0


# --- 4. Core Risk Calculation ---
D0 = 10.0; T0 = 60.0; V0 = 7.0 

def calculate_R_final_revised(d_min, delta_t, V_rel, alt_km, lat, lon, analysis_time):
    R_geo = math.exp(-d_min / D0); T_f = math.exp(-delta_t / T0); V_f = math.exp(1 - (V_rel / V0)) 
    R_kin = T_f * V_f
    
    W_ops = fetch_operational_weight(lat, lon, analysis_time)         # EarthData (Cloud)
    W_space = fetch_odpo_persistence_weight(alt_km)                   # NOAA (Space Weather/MOCAT Influence)
    
    R_final = W_space * W_ops * ((R_geo + R_kin) / 2.0)
    
    return min(1.0, max(0.0, R_final)) 

# --- 5. TLE Loading and Propagation / Location Helpers ---

def distance_km_to_altitude_km(distance_from_center_km):
    EARTH_RADIUS = 6378.135 
    return distance_from_center_km - EARTH_RADIUS

def calculate_latitude(x, y, z):
    r_xy = math.sqrt(x**2 + y**2)
    return math.degrees(math.atan2(z, r_xy))

def calculate_longitude(x, y):
    return math.degrees(math.atan2(y, x))

def load_tle_data(file_path="spacetrack_leo_3le.txt"):
    satellites = {}
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        i = 0
        while i < len(lines):
            name = lines[i].strip()
            line1 = lines[i+1].strip()
            line2 = lines[i+2].strip()
            satellite = Satrec.twoline2rv(line1, line2, WGS72)
            satellites[name] = satellite
            i += 3

        print(f"[+] INFO: Successfully loaded {len(satellites)} satellites.")
        return satellites
    except FileNotFoundError:
        print(f"[x] CRITICAL ERROR: TLE file not found at {file_path}. Cannot run analysis.")
        return {}
    except IndexError:
        # Improved error message for debugging
        print(f"[x] CRITICAL ERROR: TLE file is improperly formatted (not groups of 3 lines). Cannot run analysis.")
        return {}
    except Exception as e:
        print(f"[x] An unexpected error occurred during TLE loading: {e}")
        return {}

def propagate_single(sat, analysis_time):
    jd, fr = jday(analysis_time.year, analysis_time.month, analysis_time.day, 
                      analysis_time.hour, analysis_time.minute, analysis_time.second + analysis_time.microsecond / 1e6)
    e, r, v = sat.sgp4(jd, fr)
    if e != 0: return None 
    r = list(r) 
    lat = calculate_latitude(r[0], r[1], r[2])
    lon = calculate_longitude(r[0], r[1])
    return {"lat": lat, "lon": lon, "sat": sat, "r_km": math.sqrt(sum(c**2 for c in r))}

def propagate_and_compare(sat1, sat2, analysis_time):
    jd, fr = jday(analysis_time.year, analysis_time.month, analysis_time.day, 
                      analysis_time.hour, analysis_time.minute, analysis_time.second + analysis_time.microsecond / 1e6)
    e1, r1, v1 = sat1.sgp4(jd, fr); e2, r2, v2 = sat2.sgp4(jd, fr)
    if e1 != 0 or e2 != 0: return None 
    r1, v1, r2, v2 = list(r1), list(v1), list(r2), list(v2)
    distance_vector = [r1[i] - r2[i] for i in range(3)]
    distance_km = math.sqrt(sum(c**2 for c in distance_vector)) 
    rel_velocity_vector = [v1[i] - v2[i] for i in range(3)]
    relative_velocity_km_s = math.sqrt(sum(c**2 for c in rel_velocity_vector)) 
    alt1_km = distance_km_to_altitude_km(math.sqrt(sum(c**2 for c in r1)))
    alt2_km = distance_km_to_altitude_km(math.sqrt(sum(c**2 for c in r2)))
    average_altitude_km = (alt1_km + alt2_km) / 2.0
    return {
        "distance_km": distance_km, "relative_velocity_km_s": relative_velocity_km_s,
        "delta_t_seconds": 0.0, "average_altitude_km": average_altitude_km,
        "lat": calculate_latitude(r1[0], r1[1], r1[2]), 
        "lon": calculate_longitude(r1[0], r1[1])
    }


# --- 6. Main Execution Functions ---

def filter_satellites_by_fir(all_satellites, analysis_time):
    global FIR_BOUNDARIES
    print("[-] INFO: Starting geographic pre-filter (only keeping satellites over defined FIRs)...")
    filtered_satellites = {}
    for name, sat in all_satellites.items():
        state = propagate_single(sat, analysis_time)
        if state is None: continue
        is_over_fir = False
        for bounds in FIR_BOUNDARIES.values():
            if (bounds['lat_min'] <= state['lat'] <= bounds['lat_max'] and 
                bounds['lon_min'] <= state['lon'] <= bounds['lon_max']):
                is_over_fir = True
                break
        
        if is_over_fir:
            filtered_satellites[name] = sat
            
    print(f"[+] INFO: Pre-filter complete. {len(filtered_satellites)} satellites are over the target FIRs.")
    return filtered_satellites


def run_full_risk_analysis(relevant_satellites, analysis_time=None):
    if analysis_time is None: analysis_time = datetime.now(UTC)
    events = []; names = list(relevant_satellites.keys())
    total_comparisons = 0; 
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            total_comparisons += 1
            name1, name2 = names[i], names[j]
            sat1, sat2 = relevant_satellites[name1], relevant_satellites[name2]
            state = propagate_and_compare(sat1, sat2, analysis_time)
            if state is None: continue
            
            R_final = calculate_R_final_revised(
                d_min=state["distance_km"], delta_t=state["delta_t_seconds"], V_rel=state["relative_velocity_km_s"],
                alt_km=state["average_altitude_km"], lat=state["lat"], lon=state["lon"], analysis_time=analysis_time
            )
            
            category = "Danger" if R_final > 0.8 else ("Attention" if R_final > 0.5 else "Safe")
            
            if category != "Safe":
                fir_name = find_fir_by_location(state["lat"], state["lon"])
                country1, country2 = get_satellite_country(name1), get_satellite_country(name2)
                
                events.append({
                    "satellite1": name1, "satellite2": name2, "risk_score": R_final,
                    "risk_category": category, "distance_km": state["distance_km"],
                    "relative_velocity_km_s": state["relative_velocity_km_s"],
                    "fir": fir_name, "country_of_origin_1": country1, "country_of_origin_2": country2,
                    "lat": state["lat"], "lon": state["lon"]
                })

    print(f"\n[i] INFO: Total satellite comparisons performed: {total_comparisons}")
    return sorted(events, key=lambda x: x['risk_score'], reverse=True)


if __name__ == "__main__":
    
    satellites = load_tle_data()
    
    if not satellites:
        print("\nAnalysis terminated due to missing or improperly formatted TLE data.")
    else:
        current_time = datetime.now(UTC)
        analysis_time = current_time + timedelta(minutes=5)

        print(f"\n[*] Starting LEO Risk Analysis for {len(satellites)} satellites at: {analysis_time.isoformat()}")

        # 3. GEOGRAPHIC PRE-FILTER
        relevant_satellites = filter_satellites_by_fir(satellites, analysis_time)
        
        # 4. Run the conjunction analysis
        if not relevant_satellites:
            risk_events = []; print("INFO: No relevant satellites found over target regions. Skipping conjunction analysis.")
        else:
            risk_events = run_full_risk_analysis(relevant_satellites, analysis_time)

        # 5. Print the final summary
        print("\n" + "="*90)
        print(f"| LEO CONJUNCTION RISK REPORT - {analysis_time.strftime('%Y-%m-%d %H:%M:%S UTC'):^62} |")
        print("="*90)
        
        if not risk_events:
            print("No high-risk or attention-level conjunction events detected in the target regions.")
        else:
            print(f"Found {len(risk_events)} significant event(s) requiring attention or danger warnings (R > 0.5).")
            print("-" * 90)
            print(f"{'RISK':<8} | {'SCORE':<6} | {'SATELLITE 1':<20} | {'SATELLITE 2':<20} | {'DIST (km)':<10} | {'LOCATION':<10}")
            print("-" * 90)
            
            for event in risk_events:
                # Use standard print colors for terminal output
                risk_color = "\033[91m" if event['risk_category'] == 'Danger' else "\033[93m"
                reset_color = "\033[0m"
                location_summary = f"{event['lat']:.1f}°/{event['lon']:.1f}°"
                
                print(f"{risk_color}{event['risk_category']:<8}{reset_color} | {event['risk_score']:<6.3f} | {event['satellite1']:<20} | {event['satellite2']:<20} | {event['distance_km']:<10.2f} | {location_summary:<10} ({event['fir']})")
            
            print("-" * 90)
            print("Note: R_final incorporates orbital, cloud cover (W_ops), and space weather (W_space) factors.")
            print("="*90)