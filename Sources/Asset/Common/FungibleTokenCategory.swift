import Foundation

// MARK: - FungibleTokenCategory
public struct FungibleTokenCategory: Equatable {
	public let type: CategoryType
	public let tokenContainers: [FungibleTokenContainer]

	public init(
		type: CategoryType,
		tokenContainers: [FungibleTokenContainer]
	) {
		self.type = type
		self.tokenContainers = tokenContainers
	}
}

// MARK: Identifiable
extension FungibleTokenCategory: Identifiable {
	public typealias ID = CategoryType
	public var id: ID { type }
}

// MARK: FungibleTokenCategory.CategoryType
public extension FungibleTokenCategory {
	enum CategoryType {
		case xrd
		case nonXrd
	}
}
