import express from 'express';
import cors from 'cors';

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());

const generateRandomAlerts = (date = new Date()) => {
  const satellites = [
    'STARLINK 113', 'STARLINK 22', 'STARLINK 92', 'STARLINK 45', 'STARLINK 78',
    'ONEWEB 32', 'ONEWEB 66', 'ONEWEB 12', 'ONEWEB 89',
    'IRIDIUM 24', 'IRIDIUM 56', 'GLOBALSTAR 33'
  ];

  const firRegions = {
    incheon: { lat: [35, 38], lon: [124, 130] },
    fukuoka: { lat: [32, 35], lon: [128, 132] },
    pyongyang: { lat: [38, 42], lon: [124, 130] }
  };

  const alerts = [];
  const numAlerts = 8 + Math.floor(Math.random() * 5);

  for (let i = 0; i < numAlerts; i++) {
    const satA = satellites[Math.floor(Math.random() * satellites.length)];
    let satB = satellites[Math.floor(Math.random() * satellites.length)];
    while (satB === satA) {
      satB = satellites[Math.floor(Math.random() * satellites.length)];
    }

    const risk = Math.random();
    const firKeys = Object.keys(firRegions);
    const selectedFir = firKeys[Math.floor(Math.random() * firKeys.length)];
    const region = firRegions[selectedFir];

    const lat = region.lat[0] + Math.random() * (region.lat[1] - region.lat[0]);
    const lon = region.lon[0] + Math.random() * (region.lon[1] - region.lon[0]);

    alerts.push({
      id: `alert-${i}`,
      satA,
      satB,
      risk: parseFloat(risk.toFixed(2)),
      location: [parseFloat(lat.toFixed(2)), parseFloat(lon.toFixed(2))],
      fir: selectedFir,
      timestamp: date.toISOString()
    });
  }

  return alerts.sort((a, b) => b.risk - a.risk);
};

app.get('/api/alerts', (req, res) => {
  const now = new Date();
  const lastUpdate = now.toISOString().replace('T', ' ').substring(0, 16);

  const alerts = generateRandomAlerts(now);

  res.json({
    lastUpdate,
    alerts
  });
});

app.get('/api/alerts/:date', (req, res) => {
  const dateStr = req.params.date;
  const date = new Date(dateStr);

  if (isNaN(date.getTime())) {
    return res.status(400).json({ error: 'Invalid date format' });
  }

  const alerts = generateRandomAlerts(date);
  const lastUpdate = date.toISOString().replace('T', ' ').substring(0, 16);

  res.json({
    lastUpdate,
    alerts
  });
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
