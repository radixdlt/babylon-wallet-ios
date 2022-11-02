import Foundation

// MARK: - RequestMethod
public enum RequestMethod: String, Codable {
	case request
}

// MARK: - RequestType
enum RequestType: String, Codable {
	case accountAddresses
}
