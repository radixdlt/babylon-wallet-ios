// MARK: - LedgerIdentifiable
public enum LedgerIdentifiable: Sendable {
	case address(Address)
	case identifier(Identifier)

	public static func address(of account: Profile.Network.Account) -> Self {
		.address(.account(account.address, isLedgerHWAccount: account.isLedgerAccount))
	}

	public var address: String {
		formatted(.raw)
	}

	public func formatted(_ format: AddressFormat = .default) -> String {
		switch self {
		case let .address(address):
			address.formatted(format)
		case let .identifier(identifier):
			identifier.formatted(format)
		}
	}

	public var addressPrefix: String {
		switch self {
		case let .address(address):
			address.addressPrefix
		case let .identifier(identifier):
			identifier.addressPrefix
		}
	}
}

extension LedgerIdentifiable {
	public enum Identifier: Sendable {
		case transaction(IntentHash)
		case nonFungibleGlobalID(NonFungibleGlobalId)

		public var address: String {
			formatted(.raw)
		}

		public func formatted(_ format: AddressFormat = .default) -> String {
			switch self {
			case let .transaction(txId):
				txId.bech32EncodedTxId
			case let .nonFungibleGlobalID(nonFungibleGlobalId):
				nonFungibleGlobalId.formatted(format)
			}
		}

		public var addressPrefix: String {
			switch self {
			case .transaction:
				"transaction"
			case .nonFungibleGlobalID:
				"nft"
			}
		}
	}

	public enum Address: Hashable, Sendable {
		case account(AccountAddress, isLedgerHWAccount: Bool = false)
		case package(PackageAddress)
		case resource(ResourceAddress)
		case resourcePool(PoolAddress)
		case component(ComponentAddress)
		case validator(ValidatorAddress)
		// Will be displayd with full ResourceAddress+NFTLocalID
		case nonFungibleGlobalID(NonFungibleGlobalId)

		public var address: String {
			formatted(.raw)
		}

		public func formatted(_ format: AddressFormat) -> String {
			switch self {
			case let .account(accountAddress, _):
				accountAddress.formatted(format)
			case let .package(packageAddress):
				packageAddress.formatted(format)
			case let .resource(resourceAddress):
				resourceAddress.formatted(format)
			case let .resourcePool(resourcePoolAddress):
				resourcePoolAddress.formatted(format)
			case let .component(componentAddress):
				componentAddress.formatted(format)
			case let .validator(validatorAddress):
				validatorAddress.formatted(format)
			case let .nonFungibleGlobalID(nonFungible):
				nonFungible.formatted(format)
			}
		}

		public var addressPrefix: String {
			switch self {
			case .account:
				"account"
			case .package:
				"package"
			case .resource:
				"resource"
			case .resourcePool:
				"pool" // TODO: Correct?
			case .component:
				"component"
			case .validator:
				"component"
			case .nonFungibleGlobalID:
				"resource"
			}
		}
	}
}

extension LedgerIdentifiable.Address {
	public init?(address: Address) {
		switch address {
		case let .account(accountAddress):
			self = .account(accountAddress, isLedgerHWAccount: false)
		case let .resource(resourceAddress):
			self = .resource(resourceAddress)
		case let .pool(poolAddress):
			self = .resourcePool(poolAddress)
		case let .package(packageAddress):
			self = .package(packageAddress)
		case let .validator(validatorAddress):
			self = .validator(validatorAddress)
		case let .component(componentAddress):
			self = .component(componentAddress)
		default:
			return nil
		}
	}
}
