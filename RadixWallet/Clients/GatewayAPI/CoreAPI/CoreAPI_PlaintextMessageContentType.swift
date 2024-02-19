import Foundation

extension CoreAPI {
	public enum PlaintextMessageContentType: String, Codable, CaseIterable {
		case string = "String"
		case binary = "Binary"
	}
}
