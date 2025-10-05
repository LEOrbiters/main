from flask import Flask, jsonify
from dotenv import load_dotenv
import os
import requests
from datetime import datetime
import random
from traffic.data import eurofirs

load_dotenv()
 
app = Flask(__name__)

def generate_random_alerts(date=None):
    if date is None:
        date = datetime.now()
        
    satellites = [
        'STARLINK 113', 'STARLINK 22', 'STARLINK 92', 'STARLINK 45', 'STARLINK 78',
        'ONEWEB 32', 'ONEWEB 66', 'ONEWEB 12', 'ONEWEB 89',
        'IRIDIUM 24', 'IRIDIUM 56', 'GLOBALSTAR 33'
    ]

    fir_regions = {
        'incheon': {'lat': [35, 38], 'lon': [124, 130]},
        'fukuoka': {'lat': [32, 35], 'lon': [128, 132]},
        'pyongyang': {'lat': [38, 42], 'lon': [124, 130]}
    }

    alerts = []
    num_alerts = 8 + random.randint(0, 4)

    for i in range(num_alerts):
        sat_a = random.choice(satellites)
        sat_b = random.choice([s for s in satellites if s != sat_a])

        risk = round(random.random(), 2)
        selected_fir = random.choice(list(fir_regions.keys()))
        region = fir_regions[selected_fir]

        lat = round(region['lat'][0] + random.random() * (region['lat'][1] - region['lat'][0]), 2)
        lon = round(region['lon'][0] + random.random() * (region['lon'][1] - region['lon'][0]), 2)

        alerts.append({
            'id': f'alert-{i}',
            'satA': sat_a,
            'satB': sat_b,
            'risk': risk,
            'location': [lat, lon],
            'fir': selected_fir,
            'timestamp': date.isoformat()
        })

    return sorted(alerts, key=lambda x: x['risk'], reverse=True)

@app.route('/')
def home():
    return jsonify({"message": "Server is running"})

@app.route('/api/alerts')
def get_alerts():
    now = datetime.now()
    last_update = now.strftime('%Y-%m-%d %H:%M')
    alerts = generate_random_alerts(now)
    
    return jsonify({
        'lastUpdate': last_update,
        'alerts': alerts
    })

@app.route('/api/alerts/<date_str>')
def get_alerts_by_date(date_str):
    try:
        date = datetime.fromisoformat(date_str)
    except ValueError:
        return jsonify({'error': 'Invalid date format'}), 400

    alerts = generate_random_alerts(date)
    last_update = date.strftime('%Y-%m-%d %H:%M')

    return jsonify({
        'lastUpdate': last_update,
        'alerts': alerts
    })

@app.route('/api/firs')
def get_firs():
    # The eurofirs object is a GeoDataFrame. We can convert it to GeoJSON.
    return jsonify(eurofirs.head().__geo_interface__)

# @app.route('/api/airspaces')
# def get_airspaces():
    # api_key =  "ef6956e1dfa62da0811f7f2aa1d712e8"# os.getenv('OpenAIP_API_KEY')
    # if not api_key:
    #     return jsonify({'error': 'OpenAIP API key not configured on server'}), 500

    # url = 'https://api.core.openaip.net/api/airspaces'
    # headers = {
    #     'x-openaip-api-key': api_key
    # }
    # params = {
    #     'page': 1,
    #     'limit': 10,
    #     'sortBy': 'name',
    #     'sortDesc': 'true',
    #     'country': 'KR'
    # }
    # try:
    #     response = requests.get(url, headers=headers, params=params)
    #     response.raise_for_status()  # Raise an exception for bad status codes (4xx or 5xx)
    #     return jsonify(response.json())
    # except requests.exceptions.RequestException as e:
    #     return jsonify({'error': f'Failed to fetch data from OpenAIP: {e}'}), 502

if __name__ == '__main__':
    port = int(os.getenv('PORT', 3002))
    app.run(host='0.0.0.0', port=port, debug=True)