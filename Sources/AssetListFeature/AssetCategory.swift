import AccountWorthFetcher

// MARK: - AssetCategory
public struct AssetCategory: Equatable {
	public let type: CategoryType
	public let tokenContainers: [TokenWorthContainer]
}

// MARK: Identifiable
extension AssetCategory: Identifiable {
	public typealias ID = CategoryType
	public var id: ID { type }
}

// MARK: - Public Types
public extension AssetCategory {
	enum CategoryType {
		case xrd
		case nonXrd
	}
}
