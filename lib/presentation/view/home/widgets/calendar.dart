// First, update the CustomCalendar widget to fix the callback type:

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CustomCalendar extends StatefulWidget {
  final bool isTablet;
  final Function(DateTime date, List<Map<String, dynamic>>? events) onDateTapped; // Fixed type

  const CustomCalendar({
    super.key,
    required this.isTablet,
    required this.onDateTapped,
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime _currentDate;
  late DateTime _selectedDate;
  late PageController _pageController;

  final Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentDate = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day); // Set to today
    _pageController = PageController();
    _loadSampleEvents();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadSampleEvents() {
    final now = DateTime.now();
    
    // Today's events
    _events[DateTime(now.year, now.month, now.day)] = [
      {
        'title': 'FMD Vaccination Campaign',
        'time': '09:00 AM',
        'description': 'Foot and Mouth Disease vaccination for Cattle ID: C001-C015 - Critical health intervention',
        'icon': Icons.vaccines,
        'color': Colors.blue,
        'type': 'vaccination',
      },
      {
        'title': 'Daily Health Check',
        'time': '08:00 AM',
        'description': 'Morning health inspection and vital signs monitoring',
        'icon': Icons.health_and_safety,
        'color': Colors.green,
        'type': 'checkup',
      },
    ];

    // Tomorrow's events
    _events[DateTime(now.year, now.month, now.day + 1)] = [
      {
        'title': 'Monthly Health Assessment',
        'time': '10:30 AM',
        'description': 'Comprehensive health evaluation for Farm F089 - Block A cattle',
        'icon': Icons.health_and_safety,
        'color': Colors.teal,
        'type': 'checkup',
      },
      {
        'title': 'Milk Quality Testing',
        'time': '03:00 PM',
        'description': 'SCC analysis and bacterial count testing for dairy cattle',
        'icon': Icons.science,
        'color': Colors.purple,
        'type': 'test',
      },
    ];

    // Day after tomorrow's events
    _events[DateTime(now.year, now.month, now.day + 2)] = [
      {
        'title': 'Deworming Treatment',
        'time': '08:00 AM',
        'description': 'Scheduled deworming treatment for 25 cattle in Block A',
        'icon': Icons.medical_services,
        'color': Colors.orange,
        'type': 'treatment',
      },
      {
        'title': 'Pregnancy Check',
        'time': '11:00 AM',
        'description': 'Ultrasound examination for breeding program participants',
        'icon': Icons.favorite,
        'color': Colors.pink,
        'type': 'examination',
      },
    ];

    // 3 days from now
    _events[DateTime(now.year, now.month, now.day + 3)] = [
      {
        'title': 'Feed Quality Check',
        'time': '02:00 PM',
        'description': 'Nutritional analysis and feed inspection',
        'icon': Icons.restaurant_outlined,
        'color': AppColors.primaryColor,
        'type': 'inspection',
      },
    ];

    // Add more events for the rest of the month
    for (int i = 4; i <= 30; i++) {
      if (i % 3 == 0) { // Add events every 3 days
        _events[DateTime(now.year, now.month, now.day + i)] = [
          {
            'title': 'Health Checkup',
            'time': '09:00 AM',
            'description': 'Routine health inspection and monitoring',
            'icon': Icons.health_and_safety,
            'color': Colors.green,
            'type': 'checkup',
          },
        ];
      }
      if (i % 7 == 0) { // Add vaccination events weekly
        _events[DateTime(now.year, now.month, now.day + i)]?.add({
          'title': 'Vaccination Schedule',
          'time': '02:00 PM',
          'description': 'Scheduled vaccination program',
          'icon': Icons.vaccines,
          'color': Colors.blue,
          'type': 'vaccination',
        });
      }
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });

    final events = _events[DateTime(date.year, date.month, date.day)];
    widget.onDateTapped(date, events); // Pass events correctly
  }

  void _previousMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
    });
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startDate = firstDay.subtract(Duration(days: firstDay.weekday % 7));

    List<DateTime> days = [];
    for (int i = 0; i < 42; i++) {
      days.add(startDate.add(Duration(days: i)));
    }
    return days;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isCurrentMonth(DateTime date) {
    return date.month == _currentDate.month;
  }

  bool _hasEvents(DateTime date) {
    final events = _events[DateTime(date.year, date.month, date.day)];
    return events != null && events.isNotEmpty;
  }

  List<Color> _getEventColors(DateTime date) {
    final events = _events[DateTime(date.year, date.month, date.day)];
    if (events == null || events.isEmpty) return [];
    return events.map((e) => e['color'] as Color).take(3).toList();
  }

  int _getEventCount(DateTime date) {
    final events = _events[DateTime(date.year, date.month, date.day)];
    return events?.length ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(widget.isTablet ? 24 : 20),
      child: Column(
        children: [
          _buildCalendarHeader(),
          SizedBox(height: widget.isTablet ? 20 : 16),
          _buildWeekdayHeaders(),
          SizedBox(height: widget.isTablet ? 12 : 10),
          _buildCalendarGrid(),
          SizedBox(height: widget.isTablet ? 20 : 16),
          _buildEventLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _previousMonth,
          child: Container(
            padding: EdgeInsets.all(widget.isTablet ? 12 : 10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.primaryColor,
              size: widget.isTablet ? 24 : 20,
            ),
          ),
        ),
        Column(
          children: [
            Text(
              '${_getMonthName(_currentDate.month)} ${_currentDate.year}',
              style: TextStyle(
                fontSize: widget.isTablet ? 22 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextColor,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: widget.isTablet ? 4 : 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Health Schedule',
                style: TextStyle(
                  fontSize: widget.isTablet ? 12 : 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _nextMonth,
          child: Container(
            padding: EdgeInsets.all(widget.isTablet ? 12 : 10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primaryColor,
              size: widget.isTablet ? 24 : 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: widget.isTablet ? 12 : 10),
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.isTablet ? 14 : 12,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedTextColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final days = _getDaysInMonth(_currentDate);
    return Container(
      height: widget.isTablet ? 280 : 240,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
        ),
        itemCount: days.length > 35 ? 42 : 35,
        itemBuilder: (context, index) {
          if (index >= days.length) return const SizedBox();
          final date = days[index];
          return _buildCalendarDay(date);
        },
      ),
    );
  }

  Widget _buildCalendarDay(DateTime date) {
    final isToday = _isToday(date);
    final isCurrentMonth = _isCurrentMonth(date);
    final isSelected = date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
    final hasEvents = _hasEvents(date);
    final eventColors = _getEventColors(date);
    final eventCount = _getEventCount(date);

    return GestureDetector(
      onTap: () => _onDateSelected(date),
      child: Container(
        margin: EdgeInsets.all(widget.isTablet ? 3 : 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor
              : isToday
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primaryColor, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: widget.isTablet ? 16 : 14,
                  fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : isToday
                      ? AppColors.primaryColor
                      : isCurrentMonth
                      ? AppColors.primaryTextColor
                      : AppColors.mutedTextColor,
                ),
              ),
            ),
            if (hasEvents)
              Positioned(
                bottom: widget.isTablet ? 4 : 3,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < eventColors.length && i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Container(
                          width: widget.isTablet ? (i == 0 ? 8 : 6) : (i == 0 ? 6 : 5),
                          height: widget.isTablet ? (i == 0 ? 8 : 6) : (i == 0 ? 6 : 5),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : eventColors[i],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: eventColors[i].withOpacity(0.5),
                                blurRadius: 3,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (eventCount > 3) ...[
                        const SizedBox(width: 3),
                        Container(
                          width: widget.isTablet ? 12 : 10,
                          height: widget.isTablet ? 12 : 10,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '+${eventCount - 3}',
                              style: TextStyle(
                                fontSize: widget.isTablet ? 7 : 6,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppColors.primaryColor : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventLegend() {
    final legendItems = [
      {'color': Colors.blue, 'label': 'Vaccination', 'icon': Icons.vaccines},
      {'color': Colors.green, 'label': 'Checkup', 'icon': Icons.health_and_safety},
      {'color': Colors.orange, 'label': 'Treatment', 'icon': Icons.medical_services},
      {'color': Colors.red, 'label': 'Emergency', 'icon': Icons.warning},
      {'color': Colors.purple, 'label': 'Testing', 'icon': Icons.science},
      {'color': Colors.teal, 'label': 'Assessment', 'icon': Icons.assessment},
    ];

    return Container(
      padding: EdgeInsets.all(widget.isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: widget.isTablet ? 18 : 16,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: widget.isTablet ? 8 : 6),
              Text(
                'Event Types & Legend',
                style: TextStyle(
                  fontSize: widget.isTablet ? 14 : 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTextColor,
                ),
              ),
            ],
          ),
          SizedBox(height: widget.isTablet ? 12 : 10),
          Wrap(
            spacing: widget.isTablet ? 16 : 12,
            runSpacing: widget.isTablet ? 10 : 8,
            children: legendItems.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: widget.isTablet ? 20 : 16,
                    height: widget.isTablet ? 20 : 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          item['color'] as Color,
                          (item['color'] as Color).withOpacity(0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (item['color'] as Color).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      size: widget.isTablet ? 12 : 10,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: widget.isTablet ? 8 : 6),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: widget.isTablet ? 12 : 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}