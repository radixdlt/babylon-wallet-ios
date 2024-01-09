import EngineToolkit

// MARK: - TransactionKind
public enum TransactionKind: Hashable, Sendable {
	public enum ConformingTransaction: Hashable, Sendable {
		case general(ExecutionSummary.GeneralTransaction)
		case poolContribution(ExecutionSummary.PoolContribution)
		case poolRedemption(ExecutionSummary.PoolRedemption)
		case accountDepositSettings(ExecutionSummary.AccountDepositSettings)

		public var general: ExecutionSummary.GeneralTransaction? {
			guard case let .general(wrapped) = self else {
				return nil
			}
			return wrapped
		}
	}

	case conforming(ConformingTransaction)
	case nonConforming
}

extension ExecutionSummary {
	public func transactionKind() throws -> TransactionKind {
		// Empty array means non conforming transaction. ET was not able to map it to any type
		guard !detailedClassification.isEmpty else {
			return .nonConforming
		}

		// First try to get the general transaction if present
		return try if detailedClassification.contains(where: {
			if case .general = $0 { true } else { false }
		}) {
			transactionKind(.general)
		} else {
			transactionKind(detailedClassification.first!)
		}
	}
}

/// This is a temporary conversion of all transaction types into GeneralTransaction, until we have UI support for all transaction kinds
extension ExecutionSummary {
	public struct GeneralTransaction: Hashable, Sendable {
		public let accountProofs: [EngineToolkit.Address]
		public let accountWithdraws: [String: [ResourceIndicator]]
		public let accountDeposits: [String: [ResourceIndicator]]
		public let addressesInManifest: [EngineToolkit.Address]
		public let metadataOfNewlyCreatedEntities: [String: [String: MetadataValue?]]
		public let dataOfNewlyMintedNonFungibles: [String: [NonFungibleLocalId: Data]]
		public let addressesOfNewlyCreatedEntities: [EngineToolkit.Address]

		public var allAddress: [EngineToolkit.Address] {
			addressesInManifest
		}
	}

	public struct PoolContribution: Hashable, Sendable {}

	public struct PoolRedemption: Hashable, Sendable {}

	public struct AccountDepositSettings: Hashable, Sendable {
		public let resourcePreferenceChanges: [AccountAddress: [ResourceAddress: ResourcePreferenceUpdate]]
		public let defaultDepositRuleChanges: [AccountAddress: AccountDefaultDepositRule]
		public let authorizedDepositorsAdded: [AccountAddress: [ResourceOrNonFungible]]
		public let authorizedDepositorsRemoved: [AccountAddress: [ResourceOrNonFungible]]
	}

	public func transactionKind(_ manifestClass: DetailedManifestClass) throws -> TransactionKind {
		switch manifestClass {
		case .general, .transfer:
			.conforming(.general(
				.init(
					accountProofs: presentedProofs,
					accountWithdraws: accountWithdraws,
					accountDeposits: accountDeposits,
					addressesInManifest: encounteredEntities,
					metadataOfNewlyCreatedEntities: newEntities.metadata,
					dataOfNewlyMintedNonFungibles: [:],
					addressesOfNewlyCreatedEntities: newEntities.componentAddresses + newEntities.packageAddresses + newEntities.resourceAddresses
				)
			))
		case let .accountDepositSettingsUpdate(resourcePreferencesUpdates, depositModeUpdates, authorizedDepositorsAdded, authorizedDepositorsRemoved):
			try .conforming(.accountDepositSettings(
				.init(
					resourcePreferenceChanges: resourcePreferencesUpdates.mapKeyValues(
						AccountAddress.init(validatingAddress:),
						fValue: { try $0.mapKeys(ResourceAddress.init(validatingAddress:)) }
					),
					defaultDepositRuleChanges: depositModeUpdates.mapKeys(AccountAddress.init(validatingAddress:)),
					authorizedDepositorsAdded: authorizedDepositorsAdded.mapKeys(AccountAddress.init(validatingAddress:)),
					authorizedDepositorsRemoved: authorizedDepositorsRemoved.mapKeys(AccountAddress.init(validatingAddress:))
				)
			))
		case let .poolContribution(addresses, contributions):
//		case poolContribution(poolAddresses: [Address], poolContributions: [TrackedPoolContribution])

			.conforming(.poolContribution(.init()))
		case .poolRedemption:
//		case poolRedemption(poolAddresses: [Address], poolRedemptions: [TrackedPoolRedemption])
			.conforming(.poolRedemption(.init()))
		case .validatorStake, .validatorUnstake, .validatorClaim:
			.nonConforming
		}
	}
}

extension Dictionary {
	func mapKeys<U>(_ f: (Key) throws -> U) throws -> [U: Value] {
		try mapKeyValues(f, fValue: { $0 })
	}

	func mapKeyValues<U, T>(_ fKey: (Key) throws -> U, fValue: (Value) throws -> T) throws -> [U: T] {
		try .init(
			map {
				try (fKey($0.key), fValue($0.value))
			},
			uniquingKeysWith: { first, _ in first }
		)
	}
}

extension ResourceSpecifier {
	public var amount: EngineToolkit.Decimal? {
		if case let .amount(_, amount) = self {
			return amount
		}

		return nil
	}

	public var ids: [NonFungibleLocalId]? {
		if case let .ids(_, ids) = self {
			return ids
		}
		return nil
	}

	public var resourceAddress: EngineToolkit.Address {
		switch self {
		case let .amount(resourceAddress, _):
			resourceAddress
		case let .ids(resourceAddress, _):
			resourceAddress
		}
	}

	public var toResourceTracker: ResourceIndicator {
		switch self {
		case let .amount(resourceAddress, amount):
			.fungible(resourceAddress: resourceAddress, indicator: .guaranteed(amount: amount))
		case let .ids(resourceAddress, ids):
			.nonFungible(resourceAddress: resourceAddress, indicator: .byIds(ids: ids))
		}
	}
}

extension ResourceIndicator {
	public var resourceAddress: EngineToolkit.Address {
		switch self {
		case let .fungible(address, _):
			address
		case let .nonFungible(address, _):
			address
		}
	}

	public var ids: [NonFungibleLocalId]? {
		switch self {
		case .fungible:
			nil
		case let .nonFungible(_, .byAll(_, ids)):
			ids.value
		case let .nonFungible(_, .byIds(ids)):
			ids
		case let .nonFungible(_, .byAmount(_, ids)):
			ids.value
		}
	}
}

extension FungibleResourceIndicator {
	public var amount: RETDecimal {
		switch self {
		case let .guaranteed(amount):
			amount
		case let .predicted(predictedAmount):
			predictedAmount.value
		}
	}
}

extension NonFungibleResourceIndicator {
	public var ids: [NonFungibleLocalId] {
		switch self {
		case let .byIds(ids):
			ids
		case let .byAll(_, ids), let .byAmount(_, ids):
			ids.value
		}
	}
}

extension MetadataValue {
	public var string: String? {
		if case let .stringValue(value) = self {
			return value
		}
		return nil
	}

	public var stringArray: [String]? {
		if case let .stringArrayValue(value) = self {
			return value
		}
		return nil
	}

	public var url: URL? {
		if case let .urlValue(value) = self {
			return URL(string: value)
		}
		return nil
	}
}
