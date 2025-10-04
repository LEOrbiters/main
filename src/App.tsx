import { useState, useEffect, useCallback } from 'react';
import LeftPanel from './components/LeftPanel';
import MapView from './components/MapView';
import { Alert, AlertsResponse, FIRType, MapMode } from './types';

function App() {
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [lastUpdate, setLastUpdate] = useState<string>('');
  const [selectedFir, setSelectedFir] = useState<FIRType>('all');
  const [selectedAlert, setSelectedAlert] = useState<Alert | null>(null);
  const [mapMode, setMapMode] = useState<MapMode>('2D');
  const [selectedDate, setSelectedDate] = useState<string>('');
  const [availableDates, setAvailableDates] = useState<string[]>([]);

  const generateDateRange = () => {
    const dates = [];
    const today = new Date();
    for (let i = 0; i < 7; i++) {
      const date = new Date(today);
      date.setDate(today.getDate() + i);
      const formatted = `${String(date.getMonth() + 1).padStart(2, '0')}.${String(date.getDate()).padStart(2, '0')}`;
      dates.push(formatted);
    }
    return dates;
  };

  const fetchAlerts = useCallback(async () => {
    try {
      const response = await fetch('http://localhost:3001/api/alerts');
      const data: AlertsResponse = await response.json();
      setAlerts(data.alerts);
      setLastUpdate(data.lastUpdate);
    } catch (error) {
      console.error('Failed to fetch alerts:', error);
    }
  }, []);

  useEffect(() => {
    const dates = generateDateRange();
    setAvailableDates(dates);
    setSelectedDate(dates[0]);
  }, []);

  useEffect(() => {
    fetchAlerts();
    const interval = setInterval(fetchAlerts, 30000);
    return () => clearInterval(interval);
  }, [fetchAlerts]);

  const handleFirChange = (fir: FIRType) => {
    setSelectedFir(fir);
    setSelectedAlert(null);
  };

  const handleAlertClick = (alert: Alert) => {
    setSelectedAlert(alert);
  };

  const handleMapModeChange = (mode: MapMode) => {
    setMapMode(mode);
  };

  const handleDateChange = (direction: 'prev' | 'next') => {
    const currentIndex = availableDates.indexOf(selectedDate);
    if (direction === 'prev' && currentIndex > 0) {
      setSelectedDate(availableDates[currentIndex - 1]);
    } else if (direction === 'next' && currentIndex < availableDates.length - 1) {
      setSelectedDate(availableDates[currentIndex + 1]);
    }
  };

  const filteredAlerts = selectedFir === 'all'
    ? alerts
    : alerts.filter(alert => alert.fir === selectedFir);

  return (
    <div className="flex h-screen overflow-hidden">
      <LeftPanel
        alerts={alerts}
        lastUpdate={lastUpdate}
        selectedFir={selectedFir}
        onFirChange={handleFirChange}
        onAlertClick={handleAlertClick}
      />
      <MapView
        alerts={filteredAlerts}
        selectedAlert={selectedAlert}
        mapMode={mapMode}
        onMapModeChange={handleMapModeChange}
        selectedDate={selectedDate}
        onDateChange={handleDateChange}
        availableDates={availableDates}
      />
    </div>
  );
}

export default App;
