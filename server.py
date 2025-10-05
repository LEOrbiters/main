# REVISED VERSION - Implements API, Swagger, and Forecasting

from flask import Flask, jsonify
from dotenv import load_dotenv
import os
from datetime import datetime, UTC
from flask_cors import CORS 

# Imports for Swagger/Smorest and Risk Logic
from flask_smorest import Api, Blueprint 
from flask.views import MethodView 
from risk_analyzer import load_tle_data, run_full_risk_analysis, RiskEventsResponseSchema 

load_dotenv()
app = Flask(__name__)
CORS(app) # Enable CORS for frontend requests

# Flask-Smorest Configuration for Swagger
app.config["API_TITLE"] = "LEO Risk Analysis API"
app.config["API_VERSION"] = "v1"
app.config["OPENAPI_VERSION"] = "3.0.2"
app.config["OPENAPI_URL_PREFIX"] = "/"
# Serve the Swagger UI documentation 
app.config["OPENAPI_SWAGGER_UI_PATH"] = "/swagger-ui"
app.config["OPENAPI_SWAGGER_UI_URL"] = "https://cdn.jsdelivr.net/npm/swagger-ui-dist/"

api = Api(app)

# Define a blueprint for API endpoints
blp = Blueprint(
    "Risk Analysis", __name__, url_prefix="/api", description="Operations for LEO Collision Risk"
)

# Load TLE data once when the server starts
# NOTE: This assumes 'spacetrack_leo_3le.txt' is in the same directory or accessible via the path defined in risk_analyzer.py
ALL_SATELLITES = load_tle_data()
print(f"Flask Server Loaded {len(ALL_SATELLITES)} total TLEs.")

# API Endpoints

@blp.route("/risk-events")
class RiskEventNow(MethodView):
    """API endpoint to retrieve the latest LEO conjunction risk events for the current time."""

    # Decorator to document the 200 response using the schema defined in risk_analyzer.py
    @blp.response(200, RiskEventsResponseSchema)
    def get(self):
        """
        Calculates LEO conjunction risk events for the current UTC time (epoch).
        Endpoint for real-time risk monitoring.
        """
        if not ALL_SATELLITES:
            return {"error": "TLE data not loaded. Check TLE file path."}, 500

        # Execute analysis logic for now (analysis_time=None uses current UTC time)
        events = run_full_risk_analysis(ALL_SATELLITES)
        
        return {
            'timestamp': datetime.now(UTC).isoformat(),
            'events': events
        }

@blp.route("/risk-events/at-time/<string:time_str>")
class RiskEventAtTime(MethodView):
    """API endpoint to retrieve risk events for a specific future time (forecasting)."""

    @blp.response(200, RiskEventsResponseSchema)
    def get(self, time_str):
        """
        Calculates LEO conjunction risk events at the time specified by time_str (ISO 8601 format). 
        Used for forecasting future collision risk.
        Example Path: /api/risk-events/at-time/2025-10-05T10:00:00Z
        """
        try:
            # Parse the time string and ensure it has UTC timezone info
            analysis_time = datetime.fromisoformat(time_str).replace(tzinfo=UTC)
        except ValueError:
            return {"error": "Invalid time format. Use ISO 8601 format (e.g., 2025-10-05T08:00:00Z)."}, 400

        if not ALL_SATELLITES:
            return {"error": "TLE data not loaded. Check TLE file path."}, 500

        # Execute analysis logic for the specified time
        events = run_full_risk_analysis(ALL_SATELLITES, analysis_time=analysis_time)
        
        return {
            'timestamp': analysis_time.isoformat(),
            'events': events
        }
    
# Register the blueprint with the API
api.register_blueprint(blp)

# Base Routes

@app.route('/', methods=['GET'])
def home():
    return jsonify({"message": "LEO Risk Analysis Server is running. Access API at /api/risk-events. Documentation at /swagger-ui"})


if __name__ == '__main__':
    port = int(os.getenv('PORT', 3002))
    print(f"Swagger UI available at http://0.0.0.0:{port}/swagger-ui")
    app.run(host='0.0.0.0', port=port, debug=True)
