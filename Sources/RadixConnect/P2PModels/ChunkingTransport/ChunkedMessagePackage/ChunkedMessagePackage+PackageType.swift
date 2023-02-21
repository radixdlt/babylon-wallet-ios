import Foundation

extension ChunkedMessagePackage {
	public enum PackageType: String, Codable {
		case metaData
		case chunk
		case receiveMessageConfirmation
		case receiveMessageError
	}

	public var packageType: PackageType {
		switch self {
		case .metaData: return .metaData
		case .chunk: return .chunk
		case .receiveMessageConfirmation: return .receiveMessageConfirmation
		case .receiveMessageError: return .receiveMessageError
		}
	}
}
