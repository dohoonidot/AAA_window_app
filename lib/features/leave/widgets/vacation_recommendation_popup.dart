/// AI 휴가 추천 모달
///
/// 휴가 추천 결과를 표시하는 팝업

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ASPN_AI_AGENT/features/leave/models/vacation_recommendation_model.dart';
import 'package:ASPN_AI_AGENT/features/leave/providers/vacation_recommendation_provider.dart';
import 'package:ASPN_AI_AGENT/features/leave/widgets/vacation_recommendation_charts.dart';
import 'package:ASPN_AI_AGENT/features/leave/widgets/vacation_ui_constants.dart';
import 'package:ASPN_AI_AGENT/features/leave/widgets/vacation_ui_components.dart';
import 'package:ASPN_AI_AGENT/shared/utils/message_renderer/gpt_markdown_renderer.dart';
import 'package:ASPN_AI_AGENT/ui/theme/color_schemes.dart';

/// 마크다운 표 파싱 및 표시를 위한 유틸리티 클래스
class MarkdownTableParser {
  /// 마크다운 표를 파싱하여 List<List<String>>으로 변환
  static List<List<String>>? parseTable(String markdown) {
    // 다양한 줄바꿈 문자 처리
    final normalizedMarkdown =
        markdown.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final lines = normalizedMarkdown.split('\n');

    if (lines.isEmpty) return null;

    final List<List<String>> tableData = [];

    // 첫 번째 행이 표 제목인지 확인 (**|로 시작하고 |로 끝남)
    int headerStartIndex = 0;
    if (lines.length > 0 &&
        lines[0].startsWith('**') &&
        lines[0].contains('|') &&
        !lines[0].contains('---')) {
      // 표 제목 행은 건너뜀
      headerStartIndex = 1;
    }

    // 표 헤더 찾기
    int tableHeaderIndex = -1;
    for (int i = headerStartIndex; i < lines.length; i++) {
      if (lines[i].contains('|') &&
          !lines[i].contains('---') &&
          lines[i].split('|').length > 1) {
        tableHeaderIndex = i;
        break;
      }
    }

    if (tableHeaderIndex == -1) return null;

    // 헤더 파싱
    final headerLine = lines[tableHeaderIndex];
    final headerCells = _parseTableRow(headerLine);
    tableData.add(headerCells);

    // 구분선 찾기
    int dataStartIndex = tableHeaderIndex + 1;
    if (dataStartIndex < lines.length) {
      final separatorLine = lines[dataStartIndex];
      if (separatorLine.contains('|') &&
          (separatorLine.contains('---') ||
              separatorLine.contains(':--') ||
              separatorLine.contains('--:'))) {
        dataStartIndex++;
      }
    }

    // 데이터 행들 파싱
    for (int i = dataStartIndex; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('|') && !line.startsWith('**')) {
        final cells = _parseTableRow(line);
        if (cells.isNotEmpty) {
          tableData.add(cells);
        }
      } else if (!line.contains('|')) {
        break;
      }
    }

    return tableData.isNotEmpty ? tableData : null;
  }

  static List<String> _parseTableRow(String row) {
    // | 구분자로 분리하고 앞뒤 공백 제거
    final cells = row
        .split('|')
        .map((cell) => cell.trim())
        .where((cell) => cell.isNotEmpty)
        .toList();
    return cells;
  }

  /// 표가 포함된 마크다운인지 확인
  static bool containsTable(String markdown) {
    // 다양한 줄바꿈 문자 처리
    final normalizedMarkdown =
        markdown.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final lines = normalizedMarkdown.split('\n');

    // 최소 3줄 이상이어야 표로 인정 (헤더, 구분선, 최소 하나의 데이터 행)
    if (lines.length < 3) return false;

    // |가 포함된 줄들 찾기 (표 관련 줄들)
    final tableLines = lines
        .where((line) => line.trim().isNotEmpty && line.contains('|'))
        .toList();

    if (tableLines.length < 3) return false;

    // 표 헤더 찾기 (첫 번째 |가 포함된 줄)
    String? headerLine;
    int headerIndex = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.contains('|') &&
          !line.contains('---') &&
          line.split('|').length > 1) {
        headerLine = line;
        headerIndex = i;
        break;
      }
    }

    if (headerLine == null || headerIndex == -1) return false;

    // 구분선 확인 (헤더 다음 줄이 ---를 포함하는지)
    if (headerIndex + 1 >= lines.length) return false;

    final separatorLine = lines[headerIndex + 1].trim();
    if (!(separatorLine.contains('---') ||
        separatorLine.contains(':--') ||
        separatorLine.contains('--:'))) {
      return false;
    }

    // 최소 하나의 데이터 행이 있는지 확인
    int dataRowCount = 0;
    for (int i = headerIndex + 2; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.contains('|') && !line.startsWith('**')) {
        dataRowCount++;
      } else if (line.isNotEmpty && !line.contains('|')) {
        break; // 표가 끝남
      }
    }

    return dataRowCount > 0;
  }
}

/// 마크다운 표 위젯 - 반응형 너비 지원
class MarkdownTableWidget extends StatelessWidget {
  final List<List<String>> tableData;
  final bool isDarkTheme;

  const MarkdownTableWidget({
    super.key,
    required this.tableData,
    required this.isDarkTheme,
  });

  @override
  Widget build(BuildContext context) {
    if (tableData.isEmpty) return const SizedBox.shrink();

    final columnCount = tableData.isNotEmpty ? tableData[0].length : 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth.clamp(0, 500)
            : 500.0;
        final columnWidths = calculateResponsiveColumnWidths(
          constraints: constraints,
          columnCount: columnCount,
          borderWidth: 0.5,
          tableWidth: tableWidth.toDouble(),
        );

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: tableWidth.toDouble(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isDarkTheme ? const Color(0xFF3A3A3A) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkTheme
                      ? const Color(0xFF505050)
                      : const Color(0xFFE9ECEF),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: columnWidths,
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: isDarkTheme
                          ? const Color(0xFF505050)
                          : const Color(0xFFE9ECEF),
                      width: 0.5,
                    ),
                    verticalInside: BorderSide(
                      color: isDarkTheme
                          ? const Color(0xFF505050)
                          : const Color(0xFFE9ECEF),
                      width: 0.5,
                    ),
                  ),
                  children: tableData.asMap().entries.map((entry) {
                    final rowIndex = entry.key;
                    final row = entry.value;
                    final isHeader = rowIndex == 0;

                    return TableRow(
                      decoration: isHeader
                          ? BoxDecoration(
                              color: isDarkTheme
                                  ? const Color(0xFF4A4A4A)
                                  : const Color(0xFFF8F9FA),
                            )
                          : null,
                      children: row.asMap().entries.map((cellEntry) {
                        final cellIndex = cellEntry.key;
                        final cell = cellEntry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            cell,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isHeader
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color:
                                  isDarkTheme ? Colors.white : Colors.black87,
                            ),
                            textAlign: cellIndex == 0
                                ? TextAlign.center
                                : TextAlign.left,
                            softWrap: true,
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 반응형 테이블 컬럼 너비 계산 함수
Map<int, TableColumnWidth> calculateResponsiveColumnWidths({
  required BoxConstraints constraints,
  required int columnCount,
  double borderWidth = 0.5,
  double? tableWidth,
}) {
  if (!constraints.hasBoundedWidth || !constraints.maxWidth.isFinite) {
    return {
      for (int i = 0; i < columnCount; i++) i: const FlexColumnWidth(),
    };
  }

  final resolvedTableWidth = (tableWidth != null && tableWidth.isFinite)
      ? tableWidth
      : constraints.maxWidth;
  final availableWidth = resolvedTableWidth - (columnCount - 1) * borderWidth;
  final columnWidth = availableWidth / columnCount;

  return {
    for (int i = 0; i < columnCount; i++) i: FixedColumnWidth(columnWidth),
  };
}

/// AI 휴가 추천 모달
class VacationRecommendationPopup extends ConsumerStatefulWidget {
  final int year;

  const VacationRecommendationPopup({
    super.key,
    required this.year,
  });

  @override
  ConsumerState<VacationRecommendationPopup> createState() =>
      _VacationRecommendationPopupState();
}

class _VacationRecommendationPopupState
    extends ConsumerState<VacationRecommendationPopup> {
  double _animatedProgress = 0.0;
  Timer? _progressTimer;
  double _targetProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _startProgressAnimation();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startProgressAnimation() {
    _progressTimer?.cancel();
    _animatedProgress = 0.0;

    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_animatedProgress < _targetProgress) {
          _animatedProgress += 0.01; // 1%씩 증가
          if (_animatedProgress > _targetProgress) {
            _animatedProgress = _targetProgress;
          }
        } else if (_animatedProgress > _targetProgress) {
          _animatedProgress = _targetProgress;
        }
      });

      // 목표 진행률에 도달하면 타이머 중지 (일시적으로)
      if (_animatedProgress >= 1.0 ||
          (_animatedProgress >= _targetProgress && _targetProgress > 0)) {
        // 완료되지 않았으면 계속 유지
      }
    });
  }

  void _updateTargetProgress(double newProgress) {
    _targetProgress = newProgress;
    if (_animatedProgress > _targetProgress) {
      _animatedProgress = _targetProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(vacationRecommendationProvider);

    // 실제 진행률 업데이트
    if (state.hasValue && !state.value!.isComplete) {
      _updateTargetProgress(state.value!.streamingProgress);
    } else if (state.isLoading) {
      _updateTargetProgress(0.3); // 로딩 중 기본 진행률
    } else if (state.hasValue && state.value!.isComplete) {
      _updateTargetProgress(1.0); // 완료
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VacationUIRadius.xLarge),
      ),
      child: Container(
        width: 750,
        height: 800,
        padding: EdgeInsets.all(VacationUISpacing.paddingXXL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkTheme
                ? VacationUIColors.darkBackgroundGradient
                : VacationUIColors.lightBackgroundGradient,
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(VacationUIRadius.xLarge),
          boxShadow: VacationUIShadows.modalShadow(isDarkTheme),
        ),
        child: Column(
          children: [
            // 헤더
            _buildHeader(context, isDarkTheme),
            const SizedBox(height: 20),
            Divider(
              height: 1,
              color: isDarkTheme
                  ? const Color(0xFF505050)
                  : const Color(0xFFE9ECEF),
            ),

            // 상단 고정 진행률 바 (스크롤되지 않음) - 애니메이션 효과 적용
            if ((state.hasValue && !state.value!.isComplete) ||
                state.isLoading) ...[
              Container(
                margin: const EdgeInsets.only(top: 20, bottom: 12),
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // 배경
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDarkTheme
                                ? [
                                    const Color(0xFF3A3A3A),
                                    const Color(0xFF2D2D2D)
                                  ]
                                : [
                                    const Color(0xFFE8E8E8),
                                    const Color(0xFFF0F0F0)
                                  ],
                          ),
                        ),
                      ),
                      // 진행률 바
                      FractionallySizedBox(
                        widthFactor: _animatedProgress,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: VacationUIColors.accentGradient,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 스크롤 가능한 내용 영역
            Expanded(
              child: state.when(
                data: (data) => _buildScrollableContent(data, isDarkTheme),
                loading: () => _buildLoadingState(isDarkTheme),
                error: (error, stackTrace) => _buildErrorState(
                  error.toString(),
                  isDarkTheme,
                  () {
                    // 재시도 로직은 외부에서 처리
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),

            // 하단 버튼
            const SizedBox(height: 20),
            _buildCloseButton(context, isDarkTheme),
          ],
        ),
      ),
    );
  }

  /// 헤더 빌드
  Widget _buildHeader(BuildContext context, bool isDarkTheme) {
    return Row(
      children: [
        const GradientIconContainer(
          icon: Icons.auto_awesome,
          size: 28,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: VacationUIColors.primaryGradient,
                ).createShader(bounds),
                child: const Text(
                  '내 휴가계획 AI 추천',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.year}년 연차 사용 계획',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.close,
            color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '닫기',
        ),
      ],
    );
  }

  /// 스크롤 가능한 내용 빌드 (진행률 바 제외)
  /// 두 영역으로 분리: 사용자 경향 분석 / 추천 계획
  Widget _buildScrollableContent(
      VacationRecommendationResponse data, bool isDarkTheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════
          // 영역 1: 사용자 경향 분석
          // ═══════════════════════════════════════════════════════════════
          _buildAnalysisSectionCard(data, isDarkTheme),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════
          // 영역 1.5: 팀 충돌 분석
          // ═══════════════════════════════════════════════════════════════
          if (data.isComplete && data.finalResponseContents.isNotEmpty)
            _buildTeamConflictAnalysis(data.finalResponseContents, isDarkTheme),

          if (data.isComplete && data.finalResponseContents.isNotEmpty)
            const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════
          // 영역 2: 추천 계획 (📅 추천 날짜가 첫 번째)
          // ═══════════════════════════════════════════════════════════════
          if (data.isComplete)
            _buildRecommendationSectionCard(data, isDarkTheme),
        ],
      ),
    );
  }

  /// 영역 1: 사용자 경향 분석 카드
  Widget _buildAnalysisSectionCard(
      VacationRecommendationResponse data, bool isDarkTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkTheme
              ? [const Color(0xFF2A2A2A), const Color(0xFF1E1E1E)]
              : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDarkTheme ? const Color(0xFF3D3D3D) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '사용자 경향 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDarkTheme ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. 로딩 상태 메시지 (항상 표시)
          if (data.reasoningContents.isNotEmpty) ...[
            _buildLoadingStatusMessages(
                data.reasoningContents, data.isComplete, isDarkTheme),
            const SizedBox(height: 20),
          ],

          // 2. 과거 휴가 사용 내역 차트
          if (data.leavesData != null &&
              data.leavesData!.monthlyUsage.isNotEmpty) ...[
            _buildSubSectionTitle('📈 과거 휴가 사용 내역', isDarkTheme),
            const SizedBox(height: 12),
            GradientCard(
              isDarkTheme: isDarkTheme,
              child: MonthlyDistributionChart(
                monthlyData: data.leavesData!.monthlyUsage,
                isDarkTheme: isDarkTheme,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 3. 요일별 연차 사용량
          if (data.isComplete &&
              data.weekdayCountsData != null &&
              data.weekdayCountsData!.counts.isNotEmpty) ...[
            _buildSubSectionTitle('📊 요일별 연차 사용량', isDarkTheme),
            const SizedBox(height: 12),
            GradientCard(
              isDarkTheme: isDarkTheme,
              child: WeekdayDistributionChart(
                weekdayData: data.weekdayCountsData!.counts,
                isDarkTheme: isDarkTheme,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 4. 공휴일 인접 사용률
          if (data.isComplete && data.holidayAdjacentUsageRate != null) ...[
            _buildSubSectionTitle('🎯 공휴일 인접 사용률', isDarkTheme),
            const SizedBox(height: 12),
            GradientCard(
              isDarkTheme: isDarkTheme,
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 180,
                child: HolidayAdjacentUsageRateChart(
                  usageRate: data.holidayAdjacentUsageRate!,
                  isDarkTheme: isDarkTheme,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 5. 경향 분석 텍스트 (📊 이후 마크다운 - 스트리밍 중)
          if (data.isAfterAnalysisMarker &&
              data.markdownBuffer.isNotEmpty &&
              !data.isComplete) ...[
            _buildSubSectionTitle('💡 AI 분석 결과', isDarkTheme),
            const SizedBox(height: 12),
            _buildMarkdownContent(data.markdownBuffer, isDarkTheme),
          ],

          // 6. 완료 시 경향 분석 요약 텍스트 (finalResponseContents에서 추출)
          if (data.isComplete && data.finalResponseContents.isNotEmpty) ...[
            _buildAnalysisSummaryFromFinal(
                data.finalResponseContents, isDarkTheme),
          ],
        ],
      ),
    );
  }

  /// 영역 2: 추천 계획 카드
  Widget _buildRecommendationSectionCard(
      VacationRecommendationResponse data, bool isDarkTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkTheme
              ? [const Color(0xFF2A2A2A), const Color(0xFF1E1E1E)]
              : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDarkTheme ? const Color(0xFF3D3D3D) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '추천 계획',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDarkTheme ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. 📅 추천 날짜 테이블 (첫 번째로 표시)
          _buildRecommendedDatesTable(data.finalResponseContents, isDarkTheme),

          // 2. ✍️ 연차 사용 계획 설명 (finalResponseContents에서 추출)
          if (data.finalResponseContents.isNotEmpty) ...[
            _buildRecommendationPlanFromFinal(
                data.finalResponseContents, isDarkTheme),
          ],

          // 3. 월별 분포 차트
          if (data.monthlyDistribution.isNotEmpty) ...[
            _buildSubSectionTitle('📈 월별 연차 사용 분포', isDarkTheme),
            const SizedBox(height: 12),
            GradientCard(
              isDarkTheme: isDarkTheme,
              child: MonthlyDistributionChart(
                monthlyData: data.monthlyDistribution,
                isDarkTheme: isDarkTheme,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 4. 🏖️ 주요 연속 휴가 기간 (마크다운에서 직접 추출)
          _buildConsecutivePeriodsFromMarkdown(
              data.finalResponseContents, isDarkTheme),
        ],
      ),
    );
  }

  /// 로딩 상태 메시지 빌드 (항상 표시)
  Widget _buildLoadingStatusMessages(
      String text, bool isComplete, bool isDarkTheme) {
    // 로딩 상태 메시지 추출 (📥, 👥, 🗓️, 🧾, ✨, 📊 로 시작하는 줄)
    final lines = text.split('\n');
    final statusLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('📥') ||
          trimmed.startsWith('👥') ||
          trimmed.startsWith('🗓️') ||
          trimmed.startsWith('🧾') ||
          trimmed.startsWith('✨') ||
          trimmed.startsWith('📊')) {
        statusLines.add(trimmed);
      }
    }

    if (statusLines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkTheme
            ? const Color(0xFF1E1E1E).withOpacity(0.6)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDarkTheme ? const Color(0xFF3D3D3D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.hourglass_top,
                size: 16,
                color: isComplete
                    ? const Color(0xFF10B981)
                    : const Color(0xFF6366F1),
              ),
              const SizedBox(width: 8),
              Text(
                isComplete ? '데이터 로드 완료' : '데이터 로드 중...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkTheme ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...statusLines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  /// 서브 섹션 제목 빌드
  Widget _buildSubSectionTitle(String title, bool isDarkTheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: isDarkTheme ? Colors.white : const Color(0xFF374151),
      ),
    );
  }

  /// 추천 날짜 테이블 빌드 (MarkdownTableWidget 사용)
  Widget _buildRecommendedDatesTable(String content, bool isDarkTheme) {
    // 📅 추천 날짜 부분 추출
    final recommendIndex = content.indexOf('📅');
    if (recommendIndex == -1) return const SizedBox.shrink();

    // 📅 이후부터 테이블 끝까지 추출
    final afterRecommend = content.substring(recommendIndex);

    // 테이블 부분만 추출 (| 로 시작하는 줄들)
    final lines = afterRecommend.split('\n');
    final tableLines = <String>[];
    bool tableStarted = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('|')) {
        tableStarted = true;
        tableLines.add(trimmed);
      } else if (tableStarted && trimmed.isEmpty) {
        break; // 테이블 끝
      } else if (tableStarted && !trimmed.startsWith('|')) {
        break; // 테이블 끝
      }
    }

    if (tableLines.isEmpty) return const SizedBox.shrink();

    // 테이블 데이터 파싱
    final tableData = MarkdownTableParser.parseTable(tableLines.join('\n'));
    if (tableData == null || tableData.isEmpty) return const SizedBox.shrink();

    // 📅 제목 줄에서 총 일수 추출
    String titleText = '📅 추천 휴가 날짜';
    final titleLine = lines.firstWhere(
      (l) => l.contains('📅'),
      orElse: () => '',
    );
    if (titleLine.contains('(') && titleLine.contains(')')) {
      final match = RegExp(r'\((\d+)일\)').firstMatch(titleLine);
      if (match != null) {
        titleText = '📅 추천 휴가 날짜 (${match.group(1)}일)';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubSectionTitle(titleText, isDarkTheme),
        const SizedBox(height: 12),
        MarkdownTableWidget(
          tableData: tableData,
          isDarkTheme: isDarkTheme,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 주요 연속 휴가 기간 마크다운에서 직접 추출
  Widget _buildConsecutivePeriodsFromMarkdown(
      String content, bool isDarkTheme) {
    // \n을 실제 줄바꿈으로 변환
    String processedContent = content
        .replaceAll('\\n', '\n')
        .replaceAll(RegExp(r'\r\n'), '\n')
        .replaceAll(RegExp(r'\r'), '\n');

    // "**주요 연속 휴가 기간:**" 이후 부분 추출
    final periodKeyword = '**주요 연속 휴가 기간:**';
    final periodIndex = processedContent.indexOf(periodKeyword);

    if (periodIndex == -1) return const SizedBox.shrink();

    // 키워드 이후의 내용 추출
    final afterPeriod =
        processedContent.substring(periodIndex + periodKeyword.length);

    // 휴가 기간 라인들 추출 (공백이 아닌 줄들)
    final lines = afterPeriod.split('\n');
    final periodLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // 날짜 패턴이 포함된 줄만 추출
      if (trimmed.contains(RegExp(r'\d{4}-\d{2}-\d{2}')) ||
          trimmed.contains('징검다리') ||
          trimmed.contains('연휴')) {
        periodLines.add(trimmed);
      }
    }

    if (periodLines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubSectionTitle('🏖️ 주요 연속 휴가 기간', isDarkTheme),
        const SizedBox(height: 12),
        ...periodLines.map((line) {
          // 앞의 - 또는 • 제거하고 \n 처리
          String displayText = line
              .replaceFirst(RegExp(r'^\s*[-•]\s*'), '')
              .replaceAll('\\n', '\n');
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkTheme
                    ? VacationUIColors.darkCardGradient
                    : VacationUIColors.lightCardGradient,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF667EEA).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: GradientIconContainer(
                    icon: Icons.calendar_today,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDarkTheme ? Colors.white : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// finalResponseContents에서 경향 분석 요약 추출
  Widget _buildAnalysisSummaryFromFinal(String content, bool isDarkTheme) {
    // 📊 사용자 경향 분석 완료부터 🧩 팀 충돌 분석 이전까지 추출
    final conflictIndex = content.indexOf('🧩');
    final recommendIndex = content.indexOf('📅');

    String analysisContent = '';

    if (conflictIndex != -1) {
      // 🧩가 있으면 🧩 이전까지만 추출
      analysisContent = content.substring(0, conflictIndex);
    } else if (recommendIndex != -1) {
      // 🧩가 없으면 📅 이전까지 추출
      analysisContent = content.substring(0, recommendIndex);
    } else {
      // 둘 다 없으면 전체 내용
      analysisContent = content;
    }

    // 분석 요약이 있는 경우에만 표시
    if (analysisContent.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // JSON 데이터 제거
    final cleanedContent = _removeJsonDataFromMarkdown(analysisContent);

    if (cleanedContent.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubSectionTitle('💡 경향 분석 요약', isDarkTheme),
        const SizedBox(height: 12),
        _buildMarkdownContent(cleanedContent, isDarkTheme),
      ],
    );
  }

  /// finalResponseContents에서 추천 계획 설명 추출
  Widget _buildRecommendationPlanFromFinal(String content, bool isDarkTheme) {
    // 📅 추천 날짜 이후, 주요 연속 휴가 기간 이후의 ⚠️ 경고까지 포함
    final recommendIndex = content.indexOf('📅');
    final periodKeyword = '**주요 연속 휴가 기간:**';
    final periodIndex = content.indexOf(periodKeyword);

    String planContent = '';

    if (recommendIndex != -1) {
      // 📅 이후부터
      final afterRecommend = content.substring(recommendIndex);

      // 테이블 끝 찾기 (빈 줄 이후)
      final tableEndRegex = RegExp(r'\|\s*\d+월\s*\|[^\n]*\n\s*\n');
      final tableEndMatch = tableEndRegex.firstMatch(afterRecommend);

      if (tableEndMatch != null) {
        final afterTable = afterRecommend.substring(tableEndMatch.end);

        // 주요 연속 휴가 기간 찾기
        final localPeriodIndex = afterTable.indexOf(periodKeyword);
        if (localPeriodIndex != -1) {
          // 주요 연속 휴가 기간 이후의 내용도 포함 (⚠️ 경고 포함)
          final afterPeriod = afterTable.substring(localPeriodIndex);
          // 주요 연속 휴가 기간 섹션의 끝 찾기 (빈 줄 2개 또는 다음 섹션 시작)
          final periodEndRegex = RegExp(r'\n\s*\n\s*\n');
          final periodEndMatch = periodEndRegex.firstMatch(afterPeriod);

          if (periodEndMatch != null) {
            // 주요 연속 휴가 기간 + 이후 내용 (⚠️ 경고 포함)
            planContent = afterTable.substring(0, localPeriodIndex) +
                afterPeriod.substring(0, periodEndMatch.end);
          } else {
            // 주요 연속 휴가 기간 이후 전체 포함
            planContent = afterTable;
          }
        } else {
          planContent = afterTable;
        }
      } else if (periodIndex != -1 && periodIndex > recommendIndex) {
        // 테이블이 없는 경우
        planContent = content.substring(recommendIndex, periodIndex);
        // 📅 줄 제거
        final firstNewline = planContent.indexOf('\n');
        if (firstNewline != -1) {
          planContent = planContent.substring(firstNewline + 1);
        }
      } else {
        // 📅 이후 전체 내용
        final firstNewline = afterRecommend.indexOf('\n');
        if (firstNewline != -1) {
          planContent = afterRecommend.substring(firstNewline + 1);
        } else {
          planContent = afterRecommend;
        }
      }
    } else {
      // 📅가 없는 경우 (연차가 없는 경우 등): 전체 내용 표시
      if (periodIndex != -1) {
        planContent = content.substring(0, periodIndex);
      } else {
        planContent = content;
      }
    }

    // JSON 데이터 제거
    planContent = _removeJsonDataFromMarkdown(planContent);

    if (planContent.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubSectionTitle('✍️ 연차 사용 계획 설명', isDarkTheme),
        const SizedBox(height: 12),
        _buildMarkdownContent(planContent, isDarkTheme),
        const SizedBox(height: 24),
      ],
    );
  }

  /// finalResponseContents에서 팀 충돌 분석 추출
  Widget _buildTeamConflictAnalysis(String content, bool isDarkTheme) {
    // 🧩 팀 충돌 분석 부분 추출
    final conflictIndex = content.indexOf('🧩');
    if (conflictIndex == -1) {
      return const SizedBox.shrink();
    }

    // 🧩 이후부터 📅 이전까지 추출
    final recommendIndex = content.indexOf('📅');
    String conflictContent = '';

    if (recommendIndex != -1 && recommendIndex > conflictIndex) {
      conflictContent = content.substring(conflictIndex, recommendIndex);
    } else {
      // 📅가 없으면 🧩 이후 전체 내용
      conflictContent = content.substring(conflictIndex);
    }

    // JSON 데이터 제거
    conflictContent = _removeJsonDataFromMarkdown(conflictContent);

    // 빈 줄 정리
    conflictContent = conflictContent.trim();

    if (conflictContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkTheme
              ? [const Color(0xFF2A2A2A), const Color(0xFF1E1E1E)]
              : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDarkTheme ? const Color(0xFF3D3D3D) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '팀 충돌 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDarkTheme ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 팀 충돌 분석 내용
          GradientCard(
            isDarkTheme: isDarkTheme,
            child: _buildMarkdownContent(conflictContent, isDarkTheme),
          ),
        ],
      ),
    );
  }

  /// 마크다운 렌더링 위젯 - GptMarkdownRenderer 사용
  Widget _buildMarkdownContent(String markdown, bool isDarkTheme) {
    // 서버에서 보낸 값 그대로 표시 (취소선 변환 제거)
    String processedMarkdown = markdown;

    // \n을 실제 줄바꿈으로 강제 변환
    processedMarkdown = processedMarkdown
        .replaceAll('\\n', '\n')
        .replaceAll(RegExp(r'\r\n'), '\n')
        .replaceAll(RegExp(r'\r'), '\n');

    // JSON 데이터 제거
    processedMarkdown = _removeJsonDataFromMarkdown(processedMarkdown);

    // 테마 색상 설정
    final themeColors = isDarkTheme
        ? AppColorSchemes.codingDarkScheme
        : AppColorSchemes.lightScheme;

    return GradientCard(
      isDarkTheme: isDarkTheme,
      child: GptMarkdownRenderer.renderBasicMarkdown(
        processedMarkdown,
        themeColors: themeColors,
        role: 1,
        maxWidthFactor: 0.67,
        style: TextStyle(
          fontSize: 14,
          height: 1.8,
          color: isDarkTheme ? Colors.grey[300] : Colors.grey[800],
        ),
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;

  /// 마크다운에서 JSON 데이터 제거
  String _removeJsonDataFromMarkdown(String markdown) {
    String processedMarkdown = markdown;

    // 1. "연속 휴가 선호: short{...}" 같은 패턴 제거
    processedMarkdown = processedMarkdown.replaceAll(
        RegExp(r'연속\s*휴가\s*선호\s*:\s*[^{]*\{[^{}]*"weekday_counts"[^}]*\}[^}]*',
            dotAll: true),
        '');
    processedMarkdown = processedMarkdown.replaceAll(
        RegExp(
            r'연속\s*휴가\s*선호\s*:\s*[^{]*\{[^{}]*"holiday_adjacent"[^}]*\}[^}]*',
            dotAll: true),
        '');

    // 2. short{...}, long{...} 같은 패턴 제거
    processedMarkdown = processedMarkdown.replaceAll(
        RegExp(r'\b(short|long)\s*\{[^{}]*"weekday_counts"[^}]*\}[^}]*',
            dotAll: true),
        '');
    processedMarkdown = processedMarkdown.replaceAll(
        RegExp(r'\b(short|long)\s*\{[^{}]*"holiday_adjacent"[^}]*\}[^}]*',
            dotAll: true),
        '');

    // 3. 추천 날짜에서 "}" 괄호 제거 (아이콘 바로 뒤에 오는 경우)
    processedMarkdown = processedMarkdown.replaceAll(RegExp(r'📅\s*\}'), '📅');

    // 4. weekday_counts, holiday_adjacent_usage_rate 등이 포함된 JSON 제거 (더 강력한 패턴)
    processedMarkdown = processedMarkdown.replaceAll(
        RegExp(r'[^{]*\{[^{}]*"weekday_counts"[^}]*\}[^}]*', dotAll: true), '');
    processedMarkdown = processedMarkdown.replaceAll(
        RegExp(r'[^{]*\{[^{}]*"holiday_adjacent"[^}]*\}[^}]*', dotAll: true),
        '');
    processedMarkdown = processedMarkdown.replaceAll(
        RegExp(r'[^{]*\{[^{}]*"total_leave_days"[^}]*\}[^}]*', dotAll: true),
        '');

    // 5. JSON이 포함된 라인 전체 제거
    final lines = processedMarkdown.split('\n');
    final filteredLines = <String>[];

    for (final line in lines) {
      if (!line.contains('weekday_counts') &&
          !line.contains('holiday_adjacent') &&
          !line.contains('total_leave_days') &&
          !line.contains('"mon"') &&
          !line.contains('"tue"') &&
          !line.contains('"wed"') &&
          !line.contains('"thu"') &&
          !line.contains('"fri"') &&
          !line.contains('"sat"') &&
          !line.contains('"sun"')) {
        filteredLines.add(line);
      }
    }

    processedMarkdown = filteredLines.join('\n');

    // 빈 줄 정리
    processedMarkdown =
        processedMarkdown.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    return processedMarkdown.trim();
  }

  /// 로딩 상태 빌드
  Widget _buildLoadingState(bool isDarkTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
          ),
          const SizedBox(height: 24),
          Text(
            'AI가 휴가 계획을 분석하고 있습니다...',
            style: TextStyle(
              fontSize: 14,
              color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 에러 상태 빌드
  Widget _buildErrorState(
      String error, bool isDarkTheme, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkTheme ? Colors.white : const Color(0xFF1A1D29),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 닫기 버튼 빌드
  Widget _buildCloseButton(BuildContext context, bool isDarkTheme) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkTheme
              ? [const Color(0xFF4A4A4A), const Color(0xFF3A3A3A)]
              : [const Color(0xFFF5F5F5), const Color(0xFFEEEEEE)],
        ),
        borderRadius: BorderRadius.circular(VacationUIRadius.medium),
        border: Border.all(
          color: isDarkTheme
              ? const Color(0xFF505050).withOpacity(0.5)
              : const Color(0xFFE0E0E0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(VacationUIRadius.medium),
          splashColor: const Color(0xFF667EEA).withOpacity(0.1),
          highlightColor: const Color(0xFF667EEA).withOpacity(0.05),
          child: Center(
            child: Text(
              '닫기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkTheme ? Colors.white : const Color(0xFF1A1D29),
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
