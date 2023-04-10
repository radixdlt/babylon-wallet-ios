import Logging
import SwiftLogConsoleColors
import FileLogging
import XCGLogger
import Foundation

private let baseLabel = "com.radixpublishing"

let logsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(path: "appLogs.txt")

private func makeLogger(
	label: String,
	level: Logger.Level = .debug
) -> Logger {
	Logger(label: label) { _ in
                let xcgLogger: XCGLogger = {
                        let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)
                        // Create a destination for the system console log (via NSLog)
                        let systemDestination = AppleSystemLogDestination(identifier: "advancedLogger.systemDestination")

                        // Optionally set some configuration options
                        systemDestination.outputLevel = .debug
                        systemDestination.showLogIdentifier = false
                        systemDestination.showFunctionName = true
                        systemDestination.showThreadName = true
                        systemDestination.showLevel = true
                        systemDestination.showFileName = true
                        systemDestination.showLineNumber = true
                        systemDestination.showDate = true

                        // Add the destination to the logger
                        log.add(destination: systemDestination)

                        // Create a file log destination
                        let fileDestination = FileDestination(writeToFile: logsPath!.absoluteString, identifier: "advancedLogger.fileDestination")

                        // Optionally set some configuration options
                        fileDestination.outputLevel = .debug
                        fileDestination.showLogIdentifier = false
                        fileDestination.showFunctionName = true
                        fileDestination.showThreadName = true
                        fileDestination.showLevel = true
                        fileDestination.showFileName = true
                        fileDestination.showLineNumber = true
                        fileDestination.showDate = true

                        // Process this destination in the background
                        fileDestination.logQueue = XCGLogger.logQueue

                        // Add the destination to the logger
                        log.add(destination: fileDestination)

                        // Add basic app info, version info etc, to the start of the logs
                        log.logAppDetails()

                        return log
                }()

                let xcLogger = XCGLoggerHandler(label: label, logger: xcgLogger)

		#if DEBUG
		var logger = ColorStreamLogHandler.standardOutput(
			label: label,
			logIconType: .rainbow
		)
		logger.logLevel = level
		return MultiplexLogHandler([xcLogger, logger])
		#else
		// We globally disable all logging for non DEBUG builds
		return SwiftLogNoOpLogHandler()
		#endif // DEBUG
	}
}

public let loggerGlobal = makeLogger(label: baseLabel)

extension Logger {
	public func feature(
		_ message: String,
		marker: String = "feature",
		emoji: String = "🔮"
	) {
		log(
			level: .debug, // TODO: Add support for custom log level
			Message(stringLiteral: "\(marker): \(emoji): \(message)")
		)
	}
}
