import Foundation

// MARK: - NonFungibleGlobalId
public struct NonFungibleGlobalId: DummySargon {
	public init(nonFungibleGlobalId: String) throws {
		panic()
	}

	public func localId() -> NonFungibleLocalId {
		panic()
	}

	public static func fromParts(
		resourceAddress: ResourceAddress,
		nonFungibleLocalId: NonFungibleLocalId
	) -> Self {
		panic()
	}

	public func asStr() -> String {
		panic()
	}

	public var resourceAddress: ResourceAddress {
		panic()
	}
}
