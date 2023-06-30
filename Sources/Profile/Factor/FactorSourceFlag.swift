import Foundation

public enum FactorSourceFlag: String, Sendable, Hashable, Codable {
	/// Until we have implemented "proper" deletion, we will "flag" a
	/// FactorSource as deleted by the user and hide it, meaning e.g.
	/// that in Multi-Factor Setup flows it will not show up.
	case deletedByUser
}
