// MARK: - LedgerIdentifiable
public enum LedgerIdentifiable: Sendable {
	case address(Address)
	case identifier(Identifier)

	public static func address(of account: Profile.Network.Account) -> Self {
		.address(.account(account.address, isLedgerHWAccount: account.isLedgerAccount))
	}

	public var address: String {
		switch self {
		case let .address(address):
			address.address
		case let .identifier(identifier):
			identifier.address
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
		case transaction(TXID)
		case nonFungibleGlobalID(NonFungibleGlobalId)

		public var address: String {
			switch self {
			case let .transaction(txId):
				txId.asStr()
			case let .nonFungibleGlobalID(nonFungibleGlobalId):
				nonFungibleGlobalId.asStr()
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
		case component(ComponentAddress)
		case validator(ValidatorAddress)
		// Will be displayd with full ResourceAddress+NFTLocalID
		case nonFungibleGlobalID(NonFungibleGlobalId)

		public var address: String {
			switch self {
			case let .account(accountAddress, _):
				accountAddress.address
			case let .package(packageAddress):
				packageAddress.address
			case let .resource(resourceAddress):
				resourceAddress.address
			case let .component(componentAddress):
				componentAddress.address
			case let .validator(validatorAddress):
				validatorAddress.address
			case let .nonFungibleGlobalID(id):
				id.asStr()
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
		switch address.decodedKind {
		case _ where AccountEntityType.addressSpace.contains(address.decodedKind):
			self = .account(.init(address: address.address, decodedKind: address.decodedKind), isLedgerHWAccount: false)
		case _ where ResourceEntityType.addressSpace.contains(address.decodedKind):
			self = .resource(.init(address: address.address, decodedKind: address.decodedKind))
		case _ where PackageEntityType.addressSpace.contains(address.decodedKind):
			self = .package(.init(address: address.address, decodedKind: address.decodedKind))
		case _ where ValidatorEntityType.addressSpace.contains(address.decodedKind):
			self = .validator(.init(address: address.address, decodedKind: address.decodedKind))
		case _ where ComponentEntityType.addressSpace.contains(address.decodedKind):
			self = .component(.init(address: address.address, decodedKind: address.decodedKind))
		default:
			return nil
		}
	}
}
