import Foundation

// MARK: - ResourceOrNonFungible
public enum ResourceOrNonFungible: DummySargon {
	case resource(ResourceAddress)
	case nonFungible(NonFungibleGlobalId)
}
