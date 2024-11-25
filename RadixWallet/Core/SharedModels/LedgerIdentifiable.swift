// MARK: - LedgerIdentifiable
enum LedgerIdentifiable: Sendable {
	case address(Address)
	case transaction(TransactionIntentHash)
	case preAuthorization(SubintentHash)

	static func address(of account: Account) -> Self {
		.address(.account(account.address))
	}

	var address: String {
		formatted(.raw)
	}

	func formatted(_ format: AddressFormat = .default) -> String {
		switch self {
		case let .address(address):
			address.formatted(format)
		case let .transaction(identifier):
			identifier.formatted(format)
		case let .preAuthorization(identifier):
			identifier.formatted(format)
		}
	}

	var addressPrefix: String {
		switch self {
		case let .address(address):
			address.addressPrefix
		case .transaction:
			"transaction"
		case .preAuthorization:
			"" // Subintent cannot be tracked on dashboard
		}
	}
}

// MARK: LedgerIdentifiable.Address
extension LedgerIdentifiable {
	enum Address: Hashable, Sendable, Identifiable {
		case account(AccountAddress)
		case package(PackageAddress)
		case resource(ResourceAddress)
		case resourcePool(PoolAddress)
		case component(ComponentAddress)
		case validator(ValidatorAddress)
		// Will be displayd with full ResourceAddress+NFTLocalID
		case nonFungibleGlobalID(NonFungibleGlobalId)

		var address: String {
			formatted(.raw)
		}

		func formatted(_ format: AddressFormat) -> String {
			switch self {
			case let .account(accountAddress):
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

		var addressPrefix: String {
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

		var id: String {
			switch self {
			case let .account(accountAddress):
				accountAddress.id
			case let .package(packageAddress):
				packageAddress.id
			case let .resource(resourceAddress):
				resourceAddress.id
			case let .resourcePool(resourcePoolAddress):
				resourcePoolAddress.id
			case let .component(componentAddress):
				componentAddress.id
			case let .validator(validatorAddress):
				validatorAddress.id
			case let .nonFungibleGlobalID(nonFungible):
				nonFungible.id
			}
		}
	}
}

extension LedgerIdentifiable.Address {
	init?(address: Address) {
		switch address {
		case let .account(accountAddress):
			self = .account(accountAddress)
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
