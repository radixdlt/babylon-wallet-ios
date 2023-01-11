import Logging
import SwiftLogConsoleColors

private let baseLabel = "com.radixpublishing.converse"

private func makeLogger(
	label: String,
	level: Logger.Level = .info
) -> Logger {
	Logger(label: label) { _ in
		#if DEBUG
		var logger = ColorStreamLogHandler.standardOutput(
			label: label,
			logIconType: .rainbow
		)
		logger.logLevel = level
		return logger
		#else
		// We globally disable all logging for non DEBUG builds
		return SwiftLogNoOpLogHandler()
		#endif // DEBUG
	}
}

public var loggerGlobal = makeLogger(label: baseLabel)

public extension Logger {
	func feature(
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
