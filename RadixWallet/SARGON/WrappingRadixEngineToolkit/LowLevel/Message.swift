import Foundation

// MARK: - Message
public enum Message: DummySargon {
	public enum PlaintextMessage: DummySargon {
		public init(mimeType: String, message: PlaintextMessageInner) {
			panic()
		}

		public enum PlaintextMessageInner: DummySargon {
			case str(value: String)
		}

		public var message: PlaintextMessageInner {
			panic()
		}
	}

	static var none: Self { panic() }
	case plainText(value: PlaintextMessage)
	static func encrypted(value: Any) -> Self { panic() }
}
