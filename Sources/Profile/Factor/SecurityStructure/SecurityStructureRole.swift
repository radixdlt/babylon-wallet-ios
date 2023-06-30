import Foundation

// MARK: - SecurityStructureRole
public enum SecurityStructureRole: Sendable, Hashable, Codable {
	case primary
	case recovery
	case confirmation
}
