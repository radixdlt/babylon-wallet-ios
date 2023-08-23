import EngineKit
import Prelude

// MARK: - LedgerIdentifiable
public enum LedgerIdentifiable: Sendable {
	case address(Address)
	case identifier(Identifier)

	public var address: String {
		switch self {
		case let .address(address):
			return address.address
		case let .identifier(identifier):
			return identifier.address
		}
	}

	public var addressPrefix: String {
		switch self {
		case let .address(address):
			return address.addressPrefix
		case let .identifier(identifier):
			return identifier.addressPrefix
		}
	}
}

extension LedgerIdentifiable {
	public enum Identifier: Sendable {
		case transaction(TXID)
		case nonFungibleGlobalID(NonFungibleGlobalId)

		public var address: String {
			switch self {
			case let .transaction(txId):
				return txId.asStr()
			case let .nonFungibleGlobalID(nonFungibleGlobalId):
				return nonFungibleGlobalId.asStr()
			}
		}

		public var addressPrefix: String {
			switch self {
			case .transaction:
				return "transaction"
			case .nonFungibleGlobalID:
				return "nft"
			}
		}
	}

	public enum Address: Sendable {
		case account(AccountAddress)
		case package(PackageAddress)
		case resource(ResourceAddress)
		case component(ComponentAddress)
		case validator(ValidatorAddress)
		// Will be displayd with full ResourceAddress+NFTLocalID
		case nonFungibleGlobalID(NonFungibleGlobalId)

		public var address: String {
			switch self {
			case let .account(accountAddress):
				return accountAddress.address
			case let .package(packageAddress):
				return packageAddress.address
			case let .resource(resourceAddress):
				return resourceAddress.address
			case let .component(componentAddress):
				return componentAddress.address
			case let .validator(validatorAddress):
				return validatorAddress.address
			case let .nonFungibleGlobalID(id):
				return id.asStr()
			}
		}

		public var addressPrefix: String {
			switch self {
			case .account:
				return "account"
			case .package:
				return "package"
			case .resource:
				return "resource"
			case .component:
				return "component"
			case .validator:
				return "component"
			case .nonFungibleGlobalID:
				return "resource"
			}
		}
	}
}
