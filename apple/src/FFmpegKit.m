/*
 * Copyright (c) 2018-2021 Taner Sener
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

#import "fftools_ffmpeg.h"
#import "ArchDetect.h"
#import "AtomicLong.h"
#import "FFmpegKit.h"
#import "FFmpegKitConfig.h"
#import "Packages.h"

@implementation FFmpegKit

+ (void)initialize {
    NSLog(@"Loading ffmpeg-kit.\n");

    [FFmpegKitConfig class];

    NSLog(@"Loaded ffmpeg-kit-%@-%@-%@-%@\n", [Packages getPackageName], [ArchDetect getArch], [FFmpegKitConfig getVersion], [FFmpegKitConfig getBuildDate]);
}

+ (FFmpegSession*)executeWithArguments:(NSArray*)arguments {
    FFmpegSession* session = [[FFmpegSession alloc] init:arguments];
    [FFmpegKitConfig ffmpegExecute:session];
    return session;
}

+ (FFmpegSession*)executeWithArgumentsAsync:(NSArray*)arguments withExecuteCallback:(ExecuteCallback)executeCallback {
    FFmpegSession* session = [[FFmpegSession alloc] init:arguments withExecuteCallback:executeCallback];
    [FFmpegKitConfig asyncFFmpegExecute:session];
    return session;
}

+ (FFmpegSession*)executeWithArgumentsAsync:(NSArray*)arguments withExecuteCallback:(ExecuteCallback)executeCallback withLogCallback:(LogCallback)logCallback withStatisticsCallback:(StatisticsCallback)statisticsCallback {
    FFmpegSession* session = [[FFmpegSession alloc] init:arguments withExecuteCallback:executeCallback withLogCallback:logCallback withStatisticsCallback:statisticsCallback];
    [FFmpegKitConfig asyncFFmpegExecute:session];
    return session;
}

+ (FFmpegSession*)executeWithArgumentsAsync:(NSArray*)arguments withExecuteCallback:(ExecuteCallback)executeCallback onDispatchQueue:(dispatch_queue_t)queue {
    FFmpegSession* session = [[FFmpegSession alloc] init:arguments withExecuteCallback:executeCallback];
    [FFmpegKitConfig asyncFFmpegExecute:session onDispatchQueue:queue];
    return session;
}

+ (FFmpegSession*)executeWithArgumentsAsync:(NSArray*)arguments withExecuteCallback:(ExecuteCallback)executeCallback withLogCallback:(LogCallback)logCallback withStatisticsCallback:(StatisticsCallback)statisticsCallback onDispatchQueue:(dispatch_queue_t)queue {
    FFmpegSession* session = [[FFmpegSession alloc] init:arguments withExecuteCallback:executeCallback withLogCallback:logCallback withStatisticsCallback:statisticsCallback];
    [FFmpegKitConfig asyncFFmpegExecute:session onDispatchQueue:queue];
    return session;
}

+ (FFmpegSession*)execute:(NSString*)command {
    FFmpegSession* session = [[FFmpegSession alloc] init:[FFmpegKit parseArguments:command]];
    [FFmpegKitConfig ffmpegExecute:session];
    return session;
}

+ (FFmpegSession*)executeAsync:(NSString*)command withExecuteCallback:(ExecuteCallback)executeCallback {
    FFmpegSession* session = [[FFmpegSession alloc] init:[FFmpegKit parseArguments:command] withExecuteCallback:executeCallback];
    [FFmpegKitConfig asyncFFmpegExecute:session];
    return session;
}

+ (FFmpegSession*)executeAsync:(NSString*)command withExecuteCallback:(ExecuteCallback)executeCallback withLogCallback:(LogCallback)logCallback withStatisticsCallback:(StatisticsCallback)statisticsCallback {
    FFmpegSession* session = [[FFmpegSession alloc] init:[FFmpegKit parseArguments:command] withExecuteCallback:executeCallback withLogCallback:logCallback withStatisticsCallback:statisticsCallback];
    [FFmpegKitConfig asyncFFmpegExecute:session];
    return session;
}

+ (FFmpegSession*)executeAsync:(NSString*)command withExecuteCallback:(ExecuteCallback)executeCallback onDispatchQueue:(dispatch_queue_t)queue {
    FFmpegSession* session = [[FFmpegSession alloc] init:[FFmpegKit parseArguments:command] withExecuteCallback:executeCallback];
    [FFmpegKitConfig asyncFFmpegExecute:session onDispatchQueue:queue];
    return session;
}

+ (FFmpegSession*)executeAsync:(NSString*)command withExecuteCallback:(ExecuteCallback)executeCallback withLogCallback:(LogCallback)logCallback withStatisticsCallback:(StatisticsCallback)statisticsCallback onDispatchQueue:(dispatch_queue_t)queue {
    FFmpegSession* session = [[FFmpegSession alloc] init:[FFmpegKit parseArguments:command] withExecuteCallback:executeCallback withLogCallback:logCallback withStatisticsCallback:statisticsCallback];
    [FFmpegKitConfig asyncFFmpegExecute:session onDispatchQueue:queue];
    return session;
}

+ (void)cancel {

    /*
     * ZERO (0) IS A SPECIAL SESSION ID
     * WHEN IT IS PASSED TO THIS METHOD, A SIGINT IS GENERATED WHICH CANCELS ALL ONGOING SESSIONS
     */
    cancel_operation(0);
}

+ (void)cancel:(long)sessionId {
    cancel_operation(sessionId);
}

+ (NSArray*)listSessions {
    return [FFmpegKitConfig getFFmpegSessions];
}

+ (NSArray*)parseArguments:(NSString*)command {
    NSMutableArray *argumentArray = [[NSMutableArray alloc] init];
    NSMutableString *currentArgument = [[NSMutableString alloc] init];

    bool singleQuoteStarted = false;
    bool doubleQuoteStarted = false;

    for (int i = 0; i < command.length; i++) {
        unichar previousChar;
        if (i > 0) {
            previousChar = [command characterAtIndex:(i - 1)];
        } else {
            previousChar = 0;
        }
        unichar currentChar = [command characterAtIndex:i];

        if (currentChar == ' ') {
            if (singleQuoteStarted || doubleQuoteStarted) {
                [currentArgument appendFormat: @"%C", currentChar];
            } else if ([currentArgument length] > 0) {
                [argumentArray addObject: currentArgument];
                currentArgument = [[NSMutableString alloc] init];
            }
        } else if (currentChar == '\'' && (previousChar == 0 || previousChar != '\\')) {
            if (singleQuoteStarted) {
                singleQuoteStarted = false;
            } else if (doubleQuoteStarted) {
                [currentArgument appendFormat: @"%C", currentChar];
            } else {
                singleQuoteStarted = true;
            }
        } else if (currentChar == '\"' && (previousChar == 0 || previousChar != '\\')) {
            if (doubleQuoteStarted) {
                doubleQuoteStarted = false;
            } else if (singleQuoteStarted) {
                [currentArgument appendFormat: @"%C", currentChar];
            } else {
                doubleQuoteStarted = true;
            }
        } else {
            [currentArgument appendFormat: @"%C", currentChar];
        }
    }

    if ([currentArgument length] > 0) {
        [argumentArray addObject: currentArgument];
    }

    return argumentArray;
}

+ (NSString*)argumentsToString:(NSArray*)arguments {
    if (arguments == nil) {
        return @"nil";
    }

    NSMutableString *string = [NSMutableString stringWithString:@""];
    for (int i=0; i < [arguments count]; i++) {
        NSString *argument = [arguments objectAtIndex:i];
        if (i > 0) {
            [string appendString:@" "];
        }
        [string appendString:argument];
    }

    return string;
}

@end
