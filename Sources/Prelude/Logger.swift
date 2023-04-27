import Logging
import SwiftLogConsoleColors

private let baseLabel = "com.radixpublishing"

private func makeLogger(
	label: String,
	level: Logger.Level = .error
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
