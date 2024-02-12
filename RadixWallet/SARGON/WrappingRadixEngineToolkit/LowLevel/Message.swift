import Foundation

// MARK: - Message
public enum Message: DummySargon {
	public enum PlaintextMessage: DummySargon {
		public init(mimeType: String, message: PlaintextMessageInner) {
			sargon()
		}

		public enum PlaintextMessageInner: DummySargon {
			case str(value: String)
		}

		public var message: PlaintextMessageInner {
			sargon()
		}
	}

	static var none: Self { sargon() }
	case plainText(value: PlaintextMessage)
	static func encrypted(value: Any) -> Self { sargon() }
}
