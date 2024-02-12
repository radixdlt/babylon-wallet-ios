import Foundation

// MARK: - MetadataValue
public enum MetadataValue: DummySargon {
	case stringValue(value: String)
	case urlValue(value: String)
	case publicKeyHashArrayValue(value: [RETPublicKeyHash])
	case stringArrayValue(value: [String])

	public var string: String? {
		if case let .stringValue(value) = self {
			return value
		}
		return nil
	}

	public var stringArray: [String]? {
		if case let .stringArrayValue(value) = self {
			return value
		}
		return nil
	}

	public var url: URL? {
		if case let .urlValue(value) = self {
			return URL(string: value)
		}
		return nil
	}
}
