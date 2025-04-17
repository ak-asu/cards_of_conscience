import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../reflective_feedback/models/enhanced_reflection_data.dart';

class JusticeIndexRadarChart extends StatelessWidget {
  final JusticeIndex justiceIndex;
  final double size;

  const JusticeIndexRadarChart({
    super.key,
    required this.justiceIndex,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: RadarChart(
        RadarChartData(
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.transparent),
          tickBorderData: const BorderSide(color: Colors.transparent),
          gridBorderData: BorderSide(color: Colors.grey.withOpacity(0.3)),
          tickCount: 5,
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          getTitle: (index, angle) {
            switch (index) {
              case 0:
                return RadarChartTitle(text: 'Inclusivity', angle: angle);
              case 1:
                return RadarChartTitle(text: 'Equity', angle: angle);
              case 2:
                return RadarChartTitle(text: 'Sustainability', angle: angle);
              default:
                return RadarChartTitle(text: '', angle: angle);
            }
          },
          dataSets: [
            RadarDataSet(
              fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              borderColor: Theme.of(context).colorScheme.primary,
              entryRadius: 4,
              dataEntries: [
                RadarEntry(value: justiceIndex.inclusivityScore / 100),
                RadarEntry(value: justiceIndex.equityScore / 100),
                RadarEntry(value: justiceIndex.sustainabilityScore / 100),
              ],
              borderWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class ImpactBarChart extends StatelessWidget {
  final Map<String, double> metrics;
  final String title;
  final Color barColor;
  final double maxHeight;

  const ImpactBarChart({
    super.key,
    required this.metrics,
    required this.title,
    required this.barColor,
    this.maxHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    final sortedMetrics = metrics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: maxHeight,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              minY: 0,
              groupsSpace: 12,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  //tooltipBgColor: Colors.grey.shade800,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final metric = sortedMetrics[groupIndex];
                    return BarTooltipItem(
                      '${_formatMetricName(metric.key)}\n${metric.value.toStringAsFixed(1)}%',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value >= sortedMetrics.length || value < 0) {
                        return const SizedBox.shrink();
                      }
                      final metricName = sortedMetrics[value.toInt()].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _formatMetricName(metricName, isShort: true),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value % 20 != 0) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  
                ),
                rightTitles: const AxisTitles(
                  
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              barGroups: List.generate(
                sortedMetrics.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: sortedMetrics[index].value,
                      color: barColor,
                      width: 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatMetricName(String metricName, {bool isShort = false}) {
    // Convert snake_case to Title Case
    final words = metricName.split('_');
    final formatted = words.map((word) => 
      word.isNotEmpty ? 
        '${word[0].toUpperCase()}${word.substring(1)}' : 
        '').join(' ');
    
    if (isShort && formatted.length > 12) {
      return '${formatted.substring(0, 9)}...';
    }
    
    return formatted;
  }
}

class TimeSeriesLineChart extends StatelessWidget {
  final Map<String, Map<int, double>> timeSeriesData;
  final String title;
  final List<Color> lineColors;
  final double maxHeight;

  const TimeSeriesLineChart({
    super.key,
    required this.timeSeriesData,
    required this.title,
    required this.lineColors,
    this.maxHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure we have enough colors for all lines
    final colors = lineColors.length >= timeSeriesData.length
        ? lineColors
        : List.generate(
            timeSeriesData.length,
            (index) => lineColors[index % lineColors.length],
          );

    // Get all time points (x-axis values)
    final allTimePoints = <int>{};
    for (final series in timeSeriesData.values) {
      allTimePoints.addAll(series.keys);
    }
    final sortedTimePoints = allTimePoints.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: maxHeight,
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  //tooltipBgColor: Colors.grey.shade800,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final seriesIndex = spot.barIndex;
                      final seriesName = timeSeriesData.keys.elementAt(seriesIndex);
                      
                      return LineTooltipItem(
                        '$seriesName: ${spot.y.toStringAsFixed(1)}%',
                        TextStyle(
                          color: colors[seriesIndex],
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      // Convert time points to year labels
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Yr ${value.toInt()}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      if (value % 20 != 0) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  
                ),
                rightTitles: const AxisTitles(
                  
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              minX: sortedTimePoints.first.toDouble(),
              maxX: sortedTimePoints.last.toDouble(),
              minY: 0,
              maxY: 100,
              lineBarsData: _createLineBarsData(colors, sortedTimePoints),
            ),
          ),
        ),
      ],
    );
  }

  List<LineChartBarData> _createLineBarsData(
    List<Color> colors,
    List<int> timePoints,
  ) {
    final result = <LineChartBarData>[];
    int index = 0;

    timeSeriesData.forEach((seriesName, series) {
      final spots = <FlSpot>[];

      for (final timePoint in timePoints) {
        if (series.containsKey(timePoint)) {
          spots.add(FlSpot(timePoint.toDouble(), series[timePoint]!));
        }
      }

      if (spots.isNotEmpty) {
        result.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colors[index % colors.length],
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              color: colors[index % colors.length].withOpacity(0.1),
            ),
          ),
        );
      }

      index++;
    });

    return result;
  }
}

class ComparativeBarChart extends StatelessWidget {
  final Map<String, List<double>> comparativeData;
  final List<String> categoryNames;
  final List<Color> barColors;
  final double maxHeight;

  const ComparativeBarChart({
    super.key,
    required this.comparativeData,
    required this.categoryNames,
    required this.barColors,
    this.maxHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure we have colors for all categories
    final colors = barColors.length >= categoryNames.length
        ? barColors
        : List.generate(
            categoryNames.length,
            (index) => barColors[index % barColors.length],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            'Policy Comparison',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: maxHeight,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              minY: 0,
              groupsSpace: 16,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  //tooltipBgColor: Colors.grey.shade800,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final domain = comparativeData.keys.elementAt(groupIndex);
                    final categoryName = categoryNames[rodIndex];
                    final value = comparativeData[domain]![rodIndex];
                    
                    return BarTooltipItem(
                      '$domain - $categoryName\n${value.toStringAsFixed(1)}%',
                      TextStyle(
                        color: colors[rodIndex],
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value >= comparativeData.length || value < 0) {
                        return const SizedBox.shrink();
                      }
                      final domain = comparativeData.keys.elementAt(value.toInt());
                      final formattedDomain = _formatDomainName(domain);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          formattedDomain,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value % 20 != 0) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  
                ),
                rightTitles: const AxisTitles(
                  
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              barGroups: List.generate(
                comparativeData.length,
                (index) {
                  final domain = comparativeData.keys.elementAt(index);
                  final values = comparativeData[domain]!;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: List.generate(
                      values.length,
                      (i) => BarChartRodData(
                        toY: values[i],
                        color: colors[i],
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Add legend
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(
              categoryNames.length,
              (index) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    categoryNames[index],
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDomainName(String domain) {
    // Convert domain from format like 'healthcare_policy' to 'Healthcare'
    final parts = domain.split('_');
    if (parts.isEmpty) return domain;
    
    return parts.first[0].toUpperCase() + parts.first.substring(1);
  }
}