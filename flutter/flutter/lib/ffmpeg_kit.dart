/*
 * Copyright (c) 2019-2021 Taner Sener
 *
 * This file is part of FFmpegKit.
 *
 * FFmpegKit is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * FFmpegKit is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with FFmpegKit.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:ffmpeg_kit_platform_interface/ffmpeg_kit_platform_interface.dart';
import 'package:flutter/services.dart';

import 'execute_callback.dart';
import 'ffmpeg_kit_config.dart';
import 'ffmpeg_session.dart';
import 'log_callback.dart';
import 'src/ffmpeg_kit_factory.dart';
import 'statistics_callback.dart';

class FFmpegKit {
  static FFmpegKitPlatform _platform = FFmpegKitPlatform.instance;

  static Future<FFmpegSession> executeAsync(String command,
          [ExecuteCallback? executeCallback = null,
          LogCallback? logCallback = null,
          StatisticsCallback? statisticsCallback = null]) async =>
      FFmpegKit.executeWithArgumentsAsync(parseArguments(command),
          executeCallback, logCallback, statisticsCallback);

  static Future<FFmpegSession> executeWithArgumentsAsync(
      List<String> commandArguments,
      [ExecuteCallback? executeCallback = null,
      LogCallback? logCallback = null,
      StatisticsCallback? statisticsCallback = null]) async {
    final session = await FFmpegSession.create(commandArguments,
        executeCallback, logCallback, statisticsCallback, null);

    await FFmpegKitConfig.asyncFFmpegExecute(session);

    return session;
  }

  static Future<void> cancel([int? sessionId = null]) async {
    try {
      await FFmpegKitConfig.init();
      return _platform.ffmpegKitCancel(sessionId);
    } on PlatformException catch (e, stack) {
      print("Plugin cancel error: ${e.message}");
      return Future.error("cancel failed.", stack);
    }
  }

  static Future<List<FFmpegSession>> listSessions() async {
    try {
      await FFmpegKitConfig.init();
      return _platform.ffmpegKitListSessions().then((sessions) {
        if (sessions == null) {
          return List.empty();
        } else {
          return sessions
              .map((dynamic sessionObject) => FFmpegKitFactory.mapToSession(
                  sessionObject as Map<dynamic, dynamic>))
              .map((session) => session as FFmpegSession)
              .toList();
        }
      });
    } on PlatformException catch (e, stack) {
      print("Plugin listSessions error: ${e.message}");
      return Future.error("listSessions failed.", stack);
    }
  }

  /// Parses the given [command] into arguments.
  static List<String> parseArguments(String command) {
    final List<String> argumentList = List<String>.empty(growable: true);
    StringBuffer currentArgument = new StringBuffer();

    bool singleQuoteStarted = false;
    bool doubleQuoteStarted = false;

    for (int i = 0; i < command.length; i++) {
      int? previousChar;
      if (i > 0) {
        previousChar = command.codeUnitAt(i - 1);
      } else {
        previousChar = null;
      }
      final currentChar = command.codeUnitAt(i);

      if (currentChar == ' '.codeUnitAt(0)) {
        if (singleQuoteStarted || doubleQuoteStarted) {
          currentArgument.write(String.fromCharCode(currentChar));
        } else if (currentArgument.length > 0) {
          argumentList.add(currentArgument.toString());
          currentArgument = new StringBuffer();
        }
      } else if (currentChar == '\''.codeUnitAt(0) &&
          (previousChar == null || previousChar != '\\'.codeUnitAt(0))) {
        if (singleQuoteStarted) {
          singleQuoteStarted = false;
        } else if (doubleQuoteStarted) {
          currentArgument.write(String.fromCharCode(currentChar));
        } else {
          singleQuoteStarted = true;
        }
      } else if (currentChar == '\"'.codeUnitAt(0) &&
          (previousChar == null || previousChar != '\\'.codeUnitAt(0))) {
        if (doubleQuoteStarted) {
          doubleQuoteStarted = false;
        } else if (singleQuoteStarted) {
          currentArgument.write(String.fromCharCode(currentChar));
        } else {
          doubleQuoteStarted = true;
        }
      } else {
        currentArgument.write(String.fromCharCode(currentChar));
      }
    }

    if (currentArgument.length > 0) {
      argumentList.add(currentArgument.toString());
    }

    return argumentList;
  }
}
