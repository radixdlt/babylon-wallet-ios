import Logging
import Sargon

// MARK: - SargonLoggingDriver
final class SargonLoggingDriver: LoggingDriver {
	private let logger: Logger

	init(logger: Logger = loggerGlobal) {
		self.logger = logger
	}

	func log(level: LogLevel, msg: String) {
		logger.log(level: level.loggerLevel, .init(stringLiteral: "Sargon: \(msg)"))
	}
}

private extension LogLevel {
	var loggerLevel: Logger.Level {
		switch self {
		case .error: .error
		case .warn: .warning
		case .info: .info
		case .debug: .debug
		case .trace: .trace
		}
	}
}
