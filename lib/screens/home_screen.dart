
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/holiday_service.dart';
import '../services/memo_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HolidayService holidayService = HolidayService();
  final MemoService memoService = MemoService();

  DateTime currentMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();

  List<Holiday> holidays = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadHolidays();
  }

  Future<void> loadHolidays() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await holidayService.fetchHolidays(
        currentMonth.year,
        currentMonth.month,
      );

      if (!mounted) return;

      setState(() {
        holidays = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void changeMonth(int offset) {
    setState(() {
      currentMonth = DateTime(
        currentMonth.year,
        currentMonth.month + offset,
        1,
      );

      selectedDate = currentMonth;
    });

    loadHolidays();
  }

  Holiday? holidayOn(DateTime date) {
    for (final holiday in holidays) {
      if (holiday.dateTime.year == date.year &&
          holiday.dateTime.month == date.month &&
          holiday.dateTime.day == date.day) {
        return holiday;
      }
    }

    return null;
  }

  List<DateTime?> makeCalendarDays() {
    final firstDay = DateTime(
      currentMonth.year,
      currentMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;

    // 월요일 시작 달력
    final offset = firstDay.weekday - 1;

    final totalCells = ((offset + daysInMonth + 6) ~/ 7) * 7;

    return List.generate(totalCells, (index) {
      final day = index - offset + 1;

      if (day < 1 || day > daysInMonth) {
        return null;
      }

      return DateTime(
        currentMonth.year,
        currentMonth.month,
        day,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = makeCalendarDays();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holiday Note'),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '${currentMonth.year}년 ${currentMonth.month}월',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (errorMessage != null)
                Column(
                  children: [
                    Text(
                      '공휴일 정보를 불러오지 못했습니다.',
                      style: const TextStyle(color: Colors.red),
                    ),
                    Text(errorMessage!),
                    ElevatedButton(
                      onPressed: loadHolidays,
                      child: const Text('다시 시도'),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      children: ['월', '화', '수', '목', '금', '토', '일']
                          .map(
                            (day) => Expanded(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    day,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: days.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, index) {
                        final date = days[index];

                        if (date == null) {
                          return const SizedBox();
                        }

                        final holiday = holidayOn(date);
                        final selected =
                            date.year == selectedDate.year &&
                            date.month == selectedDate.month &&
                            date.day == selectedDate.day;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDate = date;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.blue.shade100
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: selected
                                  ? Border.all(color: Colors.blue)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: holiday != null
                                        ? Colors.red
                                        : Colors.black87,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (holiday != null)
                                  Text(
                                    holiday.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Text(
                '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일 메모',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              MemoPanel(
                key: ValueKey(
                  '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
                ),
                date: selectedDate,
                service: memoService,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemoPanel extends StatefulWidget {
  final DateTime date;
  final MemoService service;

  const MemoPanel({
    super.key,
    required this.date,
    required this.service,
  });

  @override
  State<MemoPanel> createState() => _MemoPanelState();
}

class _MemoPanelState extends State<MemoPanel> {
  final controller = TextEditingController();

  bool loading = true;
  bool saving = false;
  bool hasMemo = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    loadMemo();
  }

  Future<void> loadMemo() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final memo = await widget.service.getMemo(widget.date);

      if (!mounted) return;

      controller.text = memo ?? '';

      setState(() {
        hasMemo = memo != null;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        message = '메모 조회 실패: $e';
      });
    }
  }

  Future<void> save() async {
    final content = controller.text.trim();

    if (content.isEmpty) {
      setState(() {
        message = '메모를 입력해 주세요.';
      });
      return;
    }

    setState(() {
      saving = true;
      message = '';
    });

    try {
      await widget.service.saveMemo(widget.date, content);

      if (!mounted) return;

      setState(() {
        hasMemo = true;
        message = '저장 완료!';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = '저장 실패: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Future<void> delete() async {
    try {
      await widget.service.deleteMemo(widget.date);

      if (!mounted) return;

      controller.clear();

      setState(() {
        hasMemo = false;
        message = '삭제 완료!';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = '삭제 실패: $e';
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 100,
              decoration: const InputDecoration(
                hintText: '오늘의 일정이나 한 줄 메모를 작성해 보세요.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: saving ? null : save,
                    child: Text(saving ? '저장 중...' : '메모 저장'),
                  ),
                ),
                if (hasMemo) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: delete,
                      child: const Text('삭제'),
                    ),
                  ),
                ],
              ],
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }
}
