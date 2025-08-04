import 'package:equatable/equatable.dart';

import 'package:voo_logger_devtools/domain/entities/log_entry.dart';

class LogFilter extends Equatable {
  final List<LogLevel>? levels;
  final List<String>? categories;
  final List<String>? tags;
  final String? searchQuery;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? userId;
  final String? sessionId;

  const LogFilter({
    this.levels,
    this.categories,
    this.tags,
    this.searchQuery,
    this.startTime,
    this.endTime,
    this.userId,
    this.sessionId,
  });

  LogFilter copyWith({
    List<LogLevel>? levels,
    List<String>? categories,
    List<String>? tags,
    String? searchQuery,
    DateTime? startTime,
    DateTime? endTime,
    String? userId,
    String? sessionId,
  }) =>
      LogFilter(
        levels: levels ?? this.levels,
        categories: categories ?? this.categories,
        tags: tags ?? this.tags,
        searchQuery: searchQuery ?? this.searchQuery,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        userId: userId ?? this.userId,
        sessionId: sessionId ?? this.sessionId,
      );

  bool matches(LogEntry entry) {
    if (levels != null && !levels!.contains(entry.level)) {
      return false;
    }

    if (categories != null && categories!.isNotEmpty) {
      if (entry.category == null || !categories!.contains(entry.category)) {
        return false;
      }
    }

    if (tags != null && tags!.isNotEmpty) {
      if (entry.tag == null || !tags!.contains(entry.tag)) {
        return false;
      }
    }

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      final inMessage = entry.message.toLowerCase().contains(query);
      final inCategory = entry.category?.toLowerCase().contains(query) ?? false;
      final inTag = entry.tag?.toLowerCase().contains(query) ?? false;
      final inError = entry.error?.toLowerCase().contains(query) ?? false;

      if (!inMessage && !inCategory && !inTag && !inError) {
        return false;
      }
    }

    if (startTime != null && entry.timestamp.isBefore(startTime!)) {
      return false;
    }

    if (endTime != null && entry.timestamp.isAfter(endTime!)) {
      return false;
    }

    if (userId != null && entry.userId != userId) {
      return false;
    }

    if (sessionId != null && entry.sessionId != sessionId) {
      return false;
    }

    return true;
  }

  @override
  List<Object?> get props => [
        levels,
        categories,
        tags,
        searchQuery,
        startTime,
        endTime,
        userId,
        sessionId,
      ];
}
