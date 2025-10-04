import { Rocket, Clock } from 'lucide-react';
import { Alert, FIRType } from '../types';

interface LeftPanelProps {
  alerts: Alert[];
  lastUpdate: string;
  selectedFir: FIRType;
  onFirChange: (fir: FIRType) => void;
  onAlertClick: (alert: Alert) => void;
}

export default function LeftPanel({ alerts, lastUpdate, selectedFir, onFirChange, onAlertClick }: LeftPanelProps) {
  const getRiskColor = (risk: number) => {
    if (risk > 0.7) return 'bg-red-50 border-red-300 text-red-900';
    if (risk > 0.3) return 'bg-yellow-50 border-yellow-300 text-yellow-900';
    return 'bg-green-50 border-green-300 text-green-900';
  };

  const getRiskBadgeColor = (risk: number) => {
    if (risk > 0.7) return 'bg-red-500';
    if (risk > 0.3) return 'bg-yellow-500';
    return 'bg-green-500';
  };

  const filteredAlerts = selectedFir === 'all'
    ? alerts
    : alerts.filter(alert => alert.fir === selectedFir);

  const firButtons: { id: FIRType; label: string }[] = [
    { id: 'incheon', label: '인천 FIR' },
    { id: 'fukuoka', label: '후꾸오까 FIR' },
    { id: 'pyongyang', label: '평양 FIR' },
  ];

  return (
    <div className="w-96 h-screen bg-white shadow-2xl overflow-y-auto">
      <div className="p-6">
        <div className="bg-gradient-to-r from-blue-500 to-blue-600 rounded-2xl p-6 text-white mb-6">
          <div className="flex items-center gap-3 mb-2">
            <Rocket className="w-8 h-8" />
            <h1 className="text-2xl font-bold">LEO Orbiters</h1>
          </div>
          <p className="text-sm opacity-90">안녕? LEO 위성 간의 충돌을 알려줄게!</p>
        </div>

        <div className="mb-6">
          <h2 className="text-lg font-semibold mb-3 text-gray-800">충돌 경고</h2>
          <div className="space-y-2 max-h-64 overflow-y-auto">
            {filteredAlerts.length === 0 ? (
              <p className="text-gray-500 text-sm text-center py-4">선택한 FIR에 경고가 없습니다</p>
            ) : (
              filteredAlerts.map((alert) => (
                <div
                  key={alert.id}
                  onClick={() => onAlertClick(alert)}
                  className={`border-2 rounded-lg p-3 cursor-pointer transition-all hover:shadow-md ${getRiskColor(alert.risk)}`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex-1">
                      <div className="text-sm font-medium">
                        {alert.satA} ↔ {alert.satB}
                      </div>
                    </div>
                    <div className={`${getRiskBadgeColor(alert.risk)} text-white text-xs font-bold px-2 py-1 rounded`}>
                      {alert.risk.toFixed(2)}
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="mb-6">
          <h2 className="text-lg font-semibold mb-3 text-gray-800">구역 선택</h2>
          <div className="space-y-2">
            <button
              onClick={() => onFirChange('all')}
              className={`w-full py-2 px-4 rounded-lg font-medium transition-all ${
                selectedFir === 'all'
                  ? 'bg-blue-600 text-white shadow-md'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              전체 FIR
            </button>
            {firButtons.map(({ id, label }) => (
              <button
                key={id}
                onClick={() => onFirChange(id)}
                className={`w-full py-2 px-4 rounded-lg font-medium transition-all ${
                  selectedFir === id
                    ? 'bg-blue-600 text-white shadow-md'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        <div className="mb-6">
          <h2 className="text-lg font-semibold mb-3 text-gray-800">NASA 제공 최신 소식 - LEO 잡지</h2>
          <div className="space-y-2">
            <button className="w-full py-3 px-4 bg-gradient-to-r from-slate-100 to-slate-200 rounded-lg text-left hover:shadow-md transition-all">
              <div className="text-sm font-medium text-gray-800">25.10.04 LEO 위성 충돌 위험 분석</div>
            </button>
            <button className="w-full py-3 px-4 bg-gradient-to-r from-slate-100 to-slate-200 rounded-lg text-left hover:shadow-md transition-all">
              <div className="text-sm font-medium text-gray-800">25.10.03 우주쓰레기 관측 보고서</div>
            </button>
          </div>
        </div>

        <div className="mb-6">
          <h2 className="text-lg font-semibold mb-3 text-gray-800">실시간 우주쓰레기 커뮤니티</h2>
          <div className="grid grid-cols-3 gap-2">
            <div className="aspect-square bg-gradient-to-br from-slate-200 to-slate-300 rounded-lg flex items-center justify-center">
              <Rocket className="w-6 h-6 text-slate-600" />
            </div>
            <div className="aspect-square bg-gradient-to-br from-slate-200 to-slate-300 rounded-lg flex items-center justify-center">
              <Rocket className="w-6 h-6 text-slate-600" />
            </div>
            <div className="aspect-square bg-gradient-to-br from-slate-200 to-slate-300 rounded-lg flex items-center justify-center">
              <Rocket className="w-6 h-6 text-slate-600" />
            </div>
          </div>
        </div>

        <div className="mt-auto pt-4 border-t border-gray-200">
          <div className="flex items-center gap-2 text-sm text-gray-600">
            <Clock className="w-4 h-4" />
            <span>최근 업데이트: {lastUpdate}</span>
          </div>
        </div>
      </div>
    </div>
  );
}
