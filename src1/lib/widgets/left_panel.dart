import 'package:flutter/material.dart';
import '../models/alert.dart';

class LeftPanel extends StatelessWidget {
  final List<Alert> alerts;
  final String lastUpdate;
  final FIRType selectedFir;
  final Function(FIRType) onFirChange;
  final Function(Alert) onAlertClick;

  const LeftPanel({
    super.key,
    required this.alerts,
    required this.lastUpdate,
    required this.selectedFir,
    required this.onFirChange,
    required this.onAlertClick,
  });

  Color getRiskColor(double risk) {
    if (risk > 0.7) return Colors.red.shade50;
    if (risk > 0.3) return Colors.yellow.shade50;
    return Colors.green.shade50;
  }

  Color getRiskBorderColor(double risk) {
    if (risk > 0.7) return Colors.red.shade300;
    if (risk > 0.3) return Colors.yellow.shade300;
    return Colors.green.shade300;
  }

  Color getRiskTextColor(double risk) {
    if (risk > 0.7) return Colors.red.shade900;
    if (risk > 0.3) return Colors.yellow.shade900;
    return Colors.green.shade900;
  }

  Color getRiskBadgeColor(double risk) {
    if (risk > 0.7) return Colors.red.shade500;
    if (risk > 0.3) return Colors.yellow.shade500;
    return Colors.green.shade500;
  }

  List<Alert> get filteredAlerts {
    if (selectedFir == FIRType.all) {
      return alerts;
    }
    return alerts.where((alert) => alert.fir == selectedFir.value).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 384,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.rocket_launch, color: Colors.white, size: 32),
                        const SizedBox(width: 12),
                        const Text(
                          'LEO Orbiters',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '안녕? LEO 위성 간의 충돌을 알려줄게!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '충돌 경고',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 256),
                child: filteredAlerts.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        child: const Center(
                          child: Text(
                            '선택한 FIR에 경고가 없습니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredAlerts.length,
                        itemBuilder: (context, index) {
                          final alert = filteredAlerts[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: getRiskColor(alert.risk),
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () => onAlertClick(alert),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: getRiskBorderColor(alert.risk),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${alert.satA} ↔ ${alert.satB}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: getRiskTextColor(alert.risk),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: getRiskBadgeColor(alert.risk),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          alert.risk.toStringAsFixed(2),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),
              const Text(
                '구역 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  _buildFirButton(FIRType.all),
                  const SizedBox(height: 8),
                  _buildFirButton(FIRType.incheon),
                  const SizedBox(height: 8),
                  _buildFirButton(FIRType.fukuoka),
                  const SizedBox(height: 8),
                  _buildFirButton(FIRType.pyongyang),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'NASA 제공 최신 소식 - LEO 잡지',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  _buildNewsItem('25.10.04 LEO 위성 충돌 위험 분석'),
                  const SizedBox(height: 8),
                  _buildNewsItem('25.10.03 우주쓰레기 관측 보고서'),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                '실시간 우주쓰레기 커뮤니티',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildCommunityItem()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCommunityItem()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCommunityItem()),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text(
                      '최근 업데이트: $lastUpdate',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirButton(FIRType fir) {
    final isSelected = selectedFir == fir;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => onFirChange(fir),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
          foregroundColor: isSelected ? Colors.white : const Color(0xFF374151),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          fir.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNewsItem(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade100, Colors.grey.shade200],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _buildCommunityItem() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade200, Colors.grey.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.rocket_launch,
          size: 24,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
