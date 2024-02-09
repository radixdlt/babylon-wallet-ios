import EngineToolkit

extension ExecutionSummary {
	/// Use the first supported manifest class. Returns `nil` for non-conforming transactions
	public var detailedManifestClass: DetailedManifestClass? {
		detailedClassification.first(where: \.isSupported)
	}
}

private extension DetailedManifestClass {
	var isSupported: Bool {
		switch self {
		case .general, .transfer, .poolContribution, .poolRedemption, .validatorStake, .validatorUnstake, .accountDepositSettingsUpdate, .validatorClaim:
			true
		}
	}
}

/// This is a temporary conversion of all transaction types into GeneralTransaction, until we have UI support for all transaction kinds
extension ExecutionSummary {
	public var metadataOfNewlyCreatedEntities: [String: [String: MetadataValue?]] {
		newEntities.metadata
	}

	public var dataOfNewlyMintedNonFungibles: [String: [NonFungibleLocalId: Data]] {
		[:] // TODO: Is this never populated for .general?
	}

	public var addressesOfNewlyCreatedEntities: [RETAddress] {
		newEntities.componentAddresses + newEntities.packageAddresses + newEntities.resourceAddresses
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

	public var resourceAddress: RETAddress {
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
	public var resourceAddress: RETAddress {
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
