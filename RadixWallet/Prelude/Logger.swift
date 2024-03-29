import FileLogging
import Logging
import SwiftLogConsoleColors

private let baseLabel = "com.radixpublishing"

private func makeLogger(
	label: String,
	level: Logger.Level = .error
) -> Logger {
	Logger(label: label) { _ in
		// FIXME: Instead of this, we should differentiate by build flavour. Waiting on SPM to support proper build flavours.
		#if DEBUG
		let fileLogger: LogHandler = {
			guard let path = Logger.logFilePath,
			      let handler = try? FileLogHandler(label: label, localFile: path)
			else {
				return SwiftLogNoOpLogHandler()
			}
			return handler
		}()

		var logger = ColorStreamLogHandler.standardOutput(
			label: label,
			logIconType: .rainbow
		)
		logger.logLevel = level
		return MultiplexLogHandler([fileLogger, logger])
		#else
		return SwiftLogNoOpLogHandler()
		#endif
	}
}

// MARK: - Logger.FailureSeverity
extension Logger {
	enum FailureSeverity {
		case error
		case critical
		var level: Logger.Level {
			switch self {
			case .error: .error
			case .critical: .critical
			}
		}
	}
}

func logAssertionFailure(_ errorMessage: String, severity: Logger.FailureSeverity = .error) {
	@Dependency(\.assertionFailure) var assertionFailure
	loggerGlobal.log(level: severity.level, .init(stringLiteral: errorMessage))
	assertionFailure(errorMessage)
}

public let loggerGlobal = makeLogger(label: baseLabel)

extension Logger {
	public static let logFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(path: "appLogs.txt")
	public func feature(
		_ message: String,
		marker: String = "feature",
		emoji: String = "🔮"
	) {
		log(
			level: .notice, // TODO: Add support for custom log level
			Message(stringLiteral: "\(marker): \(emoji): \(message)")
		)
	}
}
