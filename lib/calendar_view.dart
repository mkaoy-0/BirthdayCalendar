import 'dart:io';

import 'package:flutter/material.dart';

class CalendarView extends StatelessWidget {
  const CalendarView({
    super.key,
    required this.pageController,
    required this.currentMonth,
    required this.selectedDay,
    required this.daysInMonth,
    required this.selectedImages,
    required this.colorScheme,
    required this.now,
    required this.onMonthChanged,
    required this.onDayTap,
  });

  final PageController pageController;
  final int currentMonth;
  final int? selectedDay;
  final Map<int, int> daysInMonth;
  final Map<String, String> selectedImages;
  final ColorScheme colorScheme;
  final DateTime now;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onDayTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left, size: 30),
                onPressed: () => pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
              Text(
                '$currentMonth月',
                style: const TextStyle(
                  fontSize: 23,
                  letterSpacing: 2,
                  fontFamily: 'serif',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right, size: 30),
                onPressed: () => pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: (MediaQuery.of(context).size.width - 32) / 7 / 0.55 * 5.1,
          child: PageView.builder(
            controller: pageController,
            onPageChanged: (index) => onMonthChanged((index % 12) + 1),
            itemBuilder: (context, pageIndex) {
              final monthForPage = (pageIndex % 12) + 1;
              final maxDays = daysInMonth[monthForPage] ?? 30;

              return GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.55,
                ),
                itemCount: 35,
                itemBuilder: (context, index) {
                  final dayNumber = index + 1;
                  if (dayNumber > maxDays) {
                    return Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }

                  final key = '$monthForPage-$dayNumber';
                  final imagePath = selectedImages[key];
                  final hasImage = imagePath != null && imagePath.isNotEmpty;
                  final isToday =
                      now.month == monthForPage && now.day == dayNumber;
                  final isSelected =
                      selectedDay == dayNumber && currentMonth == monthForPage;

                  return InkWell(
                    onTap: () => onDayTap(dayNumber),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.onSurface, width: 0.45),
                        borderRadius: BorderRadius.circular(1),
                        color: hasImage ? colorScheme.surface : null,
                        image: hasImage
                            ? DecorationImage(
                                image: FileImage(File(imagePath)),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.4),
                                  BlendMode.srcATop,
                                ),
                              )
                            : null,
                      ),
                      child: Center(
                        child: Container(
                          width: isToday ? (isSelected ? 42 : 32) : null,
                          height: isToday ? (isSelected ? 42 : 32) : null,
                          alignment: Alignment.center,
                          decoration: isToday
                              ? BoxDecoration(
                                  color: colorScheme.inversePrimary.withValues(
                                    alpha: 0.9,
                                  ),
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Text(
                            dayNumber.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: isSelected ? 19 : 13,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Times New Roman',
                              color: hasImage
                                  ? Colors.white
                                  : colorScheme.onSurface,
                              shadows: hasImage
                                  ? const [
                                      Shadow(color: Colors.black, blurRadius: 4),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
