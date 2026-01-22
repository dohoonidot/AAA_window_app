import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ASPN_AI_AGENT/features/leave/full_calendar_modal.dart';
import 'package:ASPN_AI_AGENT/features/leave/annual_leave_notice_screen.dart';
import 'package:ASPN_AI_AGENT/features/leave/leave_grant_history_screen.dart';
import 'package:ASPN_AI_AGENT/core/config/feature_config.dart'; // 기능 표시/숨김 설정
import 'package:ASPN_AI_AGENT/features/leave/widgets/vacation_ui_constants.dart'; // 반응형 스케일링

class LeaveRequestSidebar extends ConsumerStatefulWidget {
  final bool isExpanded;
  final VoidCallback onHover;
  final VoidCallback onExit;
  final bool isPinned;
  final VoidCallback onPinToggle;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final VoidCallback onManualTap;

  const LeaveRequestSidebar({
    super.key,
    required this.isExpanded,
    required this.onHover,
    required this.onExit,
    required this.isPinned,
    required this.onPinToggle,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onManualTap,
  });

  @override
  ConsumerState<LeaveRequestSidebar> createState() =>
      _LeaveRequestSidebarState();
}

class _LeaveRequestSidebarState extends ConsumerState<LeaveRequestSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _widthAnimation = Tween<double>(
      begin: 50.0,
      end: 285.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));
  }

  @override
  void didUpdateWidget(LeaveRequestSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: widget.isPinned ? null : (_) => widget.onHover(),
      onExit: widget.isPinned ? null : (_) => widget.onExit(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: _widthAnimation.value,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isDarkTheme ? const Color(0xFF2D2D2D) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: isDarkTheme ? 0.3 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
              border: Border(
                right: BorderSide(
                  color: isDarkTheme
                      ? const Color(0xFF404040)
                      : Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: _widthAnimation.value < 100
                ? _buildCollapsedSidebar()
                : _buildExpandedSidebar(),
          );
        },
      ),
    );
  }

  Widget _buildCollapsedSidebar() {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        context.rsh(20),
        Container(
          padding: context.rp(all: 8),
          child: Icon(
            Icons.calendar_today_rounded,
            color: isDarkTheme ? const Color(0xFF64B5F6) : Colors.blue[600],
            size: context.ris(24),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedSidebar() {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: context.rp(all: 16),
          decoration: BoxDecoration(
            gradient: isDarkTheme
                ? const LinearGradient(
                    colors: [Color(0xFF404040), Color(0xFF2D2D2D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white,
                      size: context.ris(24),
                    ),
                    context.rsw(10),
                    Expanded(
                      child: Text(
                        '휴가 관리',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.rfs(18),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onPinToggle,
                      icon: Icon(
                        widget.isPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        size: context.ris(18),
                        color: Colors.white,
                      ),
                      constraints: BoxConstraints(
                        minWidth: context.rs(32),
                        minHeight: context.rs(32),
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: widget.isPinned ? '사이드바 고정 해제' : '사이드바 고정',
                    ),
                  ],
                ),
                context.rsh(16),
                _buildSidebarButton(
                  context,
                  onPressed: () => _showCalendarModal(context),
                  icon: Icons.calendar_month_rounded,
                  label: '휴가 캘린더',
                  isDarkTheme: isDarkTheme,
                ),
                context.rsh(10),
                _buildSidebarButton(
                  context,
                  onPressed: widget.onManualTap,
                  icon: Icons.menu_book_rounded,
                  label: '휴가관리 메뉴얼',
                  isDarkTheme: isDarkTheme,
                ),
                // 연차휴가 사용촉진 통지서 버튼 (조건부 표시)
                if (FeatureConfig.showAnnualLeaveNotice) ...[
                  context.rsh(10),
                  _buildSidebarButton(
                    context,
                    onPressed: () => _showAnnualLeaveNotice(context),
                    icon: Icons.description_rounded,
                    label: '연차휴가 사용촉진 통지서',
                    isDarkTheme: isDarkTheme,
                  ),
                ],
                context.rsh(10),
                _buildSidebarButton(
                  context,
                  onPressed: () => _showGrantHistory(context),
                  icon: Icons.history_rounded,
                  label: '휴가 부여 내역',
                  isDarkTheme: isDarkTheme,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 사이드바 버튼 빌더 (반응형)
  Widget _buildSidebarButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isDarkTheme,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkTheme
            ? const Color(0xFF4A4A4A)
            : Colors.white.withValues(alpha: 0.9),
        foregroundColor: isDarkTheme ? Colors.white : const Color(0xFF667eea),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: context.rbr(12),
        ),
        padding: context.rsp(vertical: 14, horizontal: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: context.ris(20)),
          context.rsw(8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.rfs(14),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showCalendarModal(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              color: isDarkTheme ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: isDarkTheme ? 0.5 : 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FullCalendarModal(
              selectedDate: widget.selectedDate,
              onDateSelected: widget.onDateSelected,
            ),
          ),
        );
      },
    );
  }

  void _showAnnualLeaveNotice(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnnualLeaveNoticeScreen(),
      ),
    );
  }

  void _showGrantHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LeaveGrantHistoryScreen(),
      ),
    );
  }
}
