export interface Alert {
  id: string;
  satA: string;
  satB: string;
  risk: number;
  location: [number, number];
  fir: string;
  timestamp: string;
}

export interface AlertsResponse {
  lastUpdate: string;
  alerts: Alert[];
}

export type FIRType = 'incheon' | 'fukuoka' | 'pyongyang' | 'all';
export type MapMode = 'FIR' | '2D' | '3D';
