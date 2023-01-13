import Foundation

public enum AddressKind: String, Codable, Sendable, Hashable {
	case resource = "Resource"
	case package = "Package"

	case accountComponent = "AccountComponent"
	case systemComponent = "SystemComponent"
	case normalComponent = "NormalComponent"
}
