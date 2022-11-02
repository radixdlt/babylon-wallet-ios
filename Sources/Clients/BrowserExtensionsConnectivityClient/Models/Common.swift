import Foundation

// MARK: - RequestMethod
public enum RequestMethod: String, Sendable, Equatable, Codable {
	case request
}

// MARK: - RequestType
public enum RequestType: String, Sendable, Equatable, Codable {
	case accountAddresses
}
