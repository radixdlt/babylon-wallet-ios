// MARK: - EntityFlag
/// Flags that can be dynamically set on a given entity
public enum EntityFlag:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible
{
	/// The entity is marked as deleted by user. Entity should still be kept in profile
	case deletedByUser
}

extension EntityFlag {
	public var description: String {
		switch self {
		case .deletedByUser: "Deleted by user"
		}
	}
}
