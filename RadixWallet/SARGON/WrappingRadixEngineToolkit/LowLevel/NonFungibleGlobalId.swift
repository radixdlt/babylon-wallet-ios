import Foundation

// MARK: - NonFungibleGlobalId
public struct NonFungibleGlobalId: DummySargon {
	public init(nonFungibleGlobalId: String) throws {
		sargon()
	}

	public func localId() -> NonFungibleLocalId {
		sargon()
	}

	public static func fromParts(
		resourceAddress: ResourceAddress,
		nonFungibleLocalId: NonFungibleLocalId
	) -> Self {
		sargon()
	}

	public func asStr() -> String {
		sargon()
	}

	public var resourceAddress: ResourceAddress {
		sargon()
	}
}
