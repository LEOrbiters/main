import { useEffect, useRef } from 'react';
import { MapContainer, TileLayer, CircleMarker, Popup, useMap } from 'react-leaflet';
import { Alert, MapMode } from '../types';
import 'leaflet/dist/leaflet.css';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface MapViewProps {
  alerts: Alert[];
  selectedAlert: Alert | null;
  mapMode: MapMode;
  onMapModeChange: (mode: MapMode) => void;
  selectedDate: string;
  onDateChange: (direction: 'prev' | 'next') => void;
  availableDates: string[];
}

function MapController({ selectedAlert }: { selectedAlert: Alert | null }) {
  const map = useMap();

  useEffect(() => {
    if (selectedAlert) {
      map.flyTo(selectedAlert.location, 8, { duration: 1 });
    }
  }, [selectedAlert, map]);

  return null;
}

export default function MapView({
  alerts,
  selectedAlert,
  mapMode,
  onMapModeChange,
  selectedDate,
  onDateChange,
  availableDates
}: MapViewProps) {
  const mapRef = useRef(null);

  const getMarkerColor = (risk: number) => {
    if (risk > 0.7) return '#ef4444';
    if (risk > 0.3) return '#eab308';
    return '#22c55e';
  };

  const currentDateIndex = availableDates.indexOf(selectedDate);

  return (
    <div className="flex-1 relative">
      <MapContainer
        ref={mapRef}
        center={[36.5, 127.5]}
        zoom={7}
        style={{ height: '100%', width: '100%' }}
        className="z-0"
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {alerts.map((alert) => (
          <CircleMarker
            key={alert.id}
            center={alert.location}
            radius={10 + alert.risk * 20}
            pathOptions={{
              color: getMarkerColor(alert.risk),
              fillColor: getMarkerColor(alert.risk),
              fillOpacity: 0.5,
              weight: 2,
            }}
          >
            <Popup>
              <div className="text-sm">
                <div className="font-bold mb-1">{alert.satA} ↔ {alert.satB}</div>
                <div>위험도: <span className="font-semibold">{alert.risk.toFixed(2)}</span></div>
                <div className="text-gray-600">위치: {alert.location[0].toFixed(2)}, {alert.location[1].toFixed(2)}</div>
              </div>
            </Popup>
          </CircleMarker>
        ))}
        <MapController selectedAlert={selectedAlert} />
      </MapContainer>

      <div className="absolute top-4 right-4 z-10 bg-white rounded-lg shadow-lg p-2">
        <div className="flex gap-2">
          {(['FIR', '2D', '3D'] as MapMode[]).map((mode) => (
            <button
              key={mode}
              onClick={() => onMapModeChange(mode)}
              className={`px-4 py-2 rounded-md font-medium transition-all ${
                mapMode === mode
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              {mode}
            </button>
          ))}
        </div>
      </div>

      <div className="absolute bottom-4 left-1/2 transform -translate-x-1/2 z-10 bg-white rounded-lg shadow-lg p-4">
        <div className="flex items-center gap-4">
          <button
            onClick={() => onDateChange('prev')}
            disabled={currentDateIndex === 0}
            className="p-2 rounded-md bg-gray-100 hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>

          <div className="flex gap-2">
            {availableDates.slice(Math.max(0, currentDateIndex - 1), currentDateIndex + 2).map((date) => (
              <div
                key={date}
                className={`px-4 py-2 rounded-md font-medium ${
                  date === selectedDate
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700'
                }`}
              >
                {date}
              </div>
            ))}
          </div>

          <button
            onClick={() => onDateChange('next')}
            disabled={currentDateIndex === availableDates.length - 1}
            className="p-2 rounded-md bg-gray-100 hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
          >
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}
