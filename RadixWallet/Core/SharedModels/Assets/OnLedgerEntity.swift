import Sargon

// MARK: - OnLedgerEntity
enum OnLedgerEntity: Sendable, Hashable, Codable, CustomDebugStringConvertible {
	var debugDescription: String {
		switch self {
		case let .account(account):
			"account: \(account)"
		case let .accountNonFungibleIds(page):
			"accountNonFungibleIds: \(page)"
		case let .resource(resource):
			"resource: \(resource)"
		case let .resourcePool(pool):
			"pool: \(pool)"
		case let .validator(validator):
			"validator: \(validator)"
		case let .genericComponent(generic):
			"genericComponent: \(generic)"
		case let .nonFungibleToken(nft):
			"nonFungibleToken: \(nft)"
		case let .locker(locker):
			"locker: \(locker)"
		}
	}

	case resource(Resource)
	case account(OnLedgerAccount)
	case resourcePool(ResourcePool)
	case validator(Validator)
	case nonFungibleToken(NonFungibleToken)
	case accountNonFungibleIds(AccountNonFungibleIdsPage)
	case genericComponent(GenericComponent)
	case locker(Locker)

	var resource: Resource? {
		guard case let .resource(resource) = self else {
			return nil
		}
		return resource
	}

	var nonFungibleToken: NonFungibleToken? {
		guard case let .nonFungibleToken(nonFungibleToken) = self else {
			return nil
		}
		return nonFungibleToken
	}

	var accountNonFungibleIds: AccountNonFungibleIdsPage? {
		guard case let .accountNonFungibleIds(ids) = self else {
			return nil
		}
		return ids
	}

	var account: OnLedgerAccount? {
		guard case let .account(account) = self else {
			return nil
		}
		return account
	}

	var resourcePool: ResourcePool? {
		guard case let .resourcePool(resourcePool) = self else {
			return nil
		}
		return resourcePool
	}

	var validator: Validator? {
		guard case let .validator(validator) = self else {
			return nil
		}
		return validator
	}

	var genericComponent: GenericComponent? {
		guard case let .genericComponent(genericComponent) = self else {
			return nil
		}
		return genericComponent
	}

	var locker: Locker? {
		guard case let .locker(locker) = self else {
			return nil
		}
		return locker
	}

	var metadata: Metadata? {
		switch self {
		case let .resource(resource):
			resource.metadata
		case let .account(account):
			account.metadata
		case let .resourcePool(resourcePool):
			resourcePool.metadata
		case let .validator(validator):
			validator.metadata
		case .nonFungibleToken, .accountNonFungibleIds:
			nil
		case let .genericComponent(genericComponent):
			genericComponent.metadata
		case let .locker(locker):
			locker.metadata
		}
	}
}

// MARK: - OnLedgerEntity.Metadata.ValueAtStateVersion + Sendable
extension OnLedgerEntity.Metadata.ValueAtStateVersion: Sendable where Value: Sendable {}

// MARK: - OnLedgerEntity.Metadata.ValueAtStateVersion + Equatable
extension OnLedgerEntity.Metadata.ValueAtStateVersion: Equatable where Value: Equatable {}

// MARK: - OnLedgerEntity.Metadata.ValueAtStateVersion + Hashable
extension OnLedgerEntity.Metadata.ValueAtStateVersion: Hashable where Value: Hashable {}

extension OnLedgerEntity.Metadata {
	init(newlyCreated: NewlyCreatedResource) {
		self.init(
			name: newlyCreated.name,
			symbol: newlyCreated.symbol,
			description: newlyCreated.description,
			iconURL: newlyCreated.iconUrl.map { URL(string: $0) } ?? nil,
			tags: newlyCreated.tags.compactMap(NonEmptyString.init(rawValue:)).map(AssetTag.custom),
			isComplete: false
		)
	}
}

extension OnLedgerEntity {
	struct Metadata: Sendable, Hashable, Codable {
		enum PublicKeyHash: Sendable, Hashable, Codable {
			case ecdsaSecp256k1(String)
			case eddsaEd25519(String)
		}

		let name: String?
		let symbol: String?
		let description: String?
		let iconURL: URL?
		let infoURL: URL?
		let tags: [AssetTag]
		let dappDefinitions: [AccountAddress]?
		let dappDefinition: AccountAddress?
		let validator: ValidatorAddress?
		let poolUnit: PoolAddress?
		let poolUnitResource: ResourceAddress?
		let claimedEntities: [String]?
		let claimedWebsites: [URL]?
		let accountType: AccountType?
		let ownerKeys: PublicKeyHashesWithStateVersion?
		let ownerBadge: OwnerBadgeWithStateVersion?
		let arbitraryItems: [ArbitraryItem]

		/// Indicates whether all the metadata has been downloaded, or if there is still more info to fetch.
		let isComplete: Bool

		struct ValueAtStateVersion<Value>: Codable where Value: Codable {
			let value: Value
			let lastUpdatedAtStateVersion: AtStateVersion

			func map<T>(_ transform: (Value) throws -> T) rethrows -> ValueAtStateVersion<T> {
				try ValueAtStateVersion<T>(
					value: transform(value),
					lastUpdatedAtStateVersion: lastUpdatedAtStateVersion
				)
			}

			func map<T>(_ transform: (Value) throws -> T?) rethrows -> ValueAtStateVersion<T>? {
				guard let transformed = try transform(value) else { return nil }
				return ValueAtStateVersion<T>(
					value: transformed,
					lastUpdatedAtStateVersion: lastUpdatedAtStateVersion
				)
			}

			func mapArray<T>(_ transform: (Value) throws -> [T]?) rethrows -> [ValueAtStateVersion<T>]? {
				guard let elements = try transform(value) else { return nil }
				return elements.map { (element: T) in
					ValueAtStateVersion<T>(value: element, lastUpdatedAtStateVersion: lastUpdatedAtStateVersion)
				}
			}
		}

		typealias OwnerBadgeWithStateVersion = ValueAtStateVersion<NonFungibleLocalId>
		typealias PublicKeyHashesWithStateVersion = ValueAtStateVersion<[PublicKeyHash]>
		typealias ArbitraryItem = GatewayAPI.EntityMetadataItem

		init(
			name: String? = nil,
			symbol: String? = nil,
			description: String? = nil,
			iconURL: URL? = nil,
			infoURL: URL? = nil,
			tags: [AssetTag] = [],
			dappDefinitions: [AccountAddress]? = nil,
			dappDefinition: AccountAddress? = nil,
			validator: ValidatorAddress? = nil,
			poolUnit: PoolAddress? = nil,
			poolUnitResource: ResourceAddress? = nil,
			claimedEntities: [String]? = nil,
			claimedWebsites: [URL]? = nil,
			accountType: AccountType? = nil,
			ownerKeys: PublicKeyHashesWithStateVersion? = nil,
			ownerBadge: OwnerBadgeWithStateVersion? = nil,
			arbitraryItems: [GatewayAPI.EntityMetadataItem] = [],
			isComplete: Bool
		) {
			self.name = name
			self.symbol = symbol
			self.description = description
			self.iconURL = iconURL
			self.infoURL = infoURL
			self.tags = tags
			self.dappDefinitions = dappDefinitions
			self.dappDefinition = dappDefinition
			self.validator = validator
			self.poolUnit = poolUnit
			self.poolUnitResource = poolUnitResource
			self.claimedEntities = claimedEntities
			self.claimedWebsites = claimedWebsites
			self.accountType = accountType
			self.ownerKeys = ownerKeys
			self.ownerBadge = ownerBadge
			self.arbitraryItems = arbitraryItems
			self.isComplete = isComplete
		}
	}

	// MARK: - AccountType
	enum AccountType: String, Sendable, Codable {
		case dappDefinition = "dapp definition"
	}

	struct Resource: Sendable, Hashable, Codable, Identifiable, CustomDebugStringConvertible {
		var id: ResourceAddress { resourceAddress }
		let resourceAddress: ResourceAddress
		let atLedgerState: AtLedgerState
		let divisibility: UInt8?
		let behaviors: [AssetBehavior]
		let totalSupply: Decimal192?
		let metadata: Metadata

		var debugDescription: String {
			"""
			\(resourceAddress.formatted())
			symbol: \(metadata.symbol ?? "???")
			name: \(metadata.name ?? "???")
			icon: \(metadata.iconURL?.absoluteString ?? "???")
			description: \(metadata.description ?? "???")
			"""
		}

		var fungibility: Fungibility {
			if resourceAddress.isFungible {
				.fungible
			} else {
				.nonFungible
			}
		}

		enum Fungibility {
			case fungible
			case nonFungible
		}

		init(
			resourceAddress: ResourceAddress,
			atLedgerState: AtLedgerState,
			divisibility: UInt8? = nil,
			behaviors: [AssetBehavior] = [],
			totalSupply: Decimal192? = nil,
			metadata: Metadata
		) {
			self.resourceAddress = resourceAddress
			self.atLedgerState = atLedgerState
			self.divisibility = divisibility
			self.behaviors = behaviors
			self.totalSupply = totalSupply
			self.metadata = metadata
		}
	}

	struct GenericComponent: Sendable, Hashable, Codable {
		let address: ComponentAddress
		let atLedgerState: AtLedgerState
		let behaviors: [AssetBehavior]
		let metadata: Metadata
	}
}

// MARK: - OnLedgerEntity.Locker
extension OnLedgerEntity {
	struct Locker: Sendable, Hashable, Codable {
		let address: LockerAddress
		let atLedgerState: AtLedgerState
		let metadata: Metadata
	}
}

extension OnLedgerEntity {
	struct NonFungibleToken: Sendable, Hashable, Identifiable, Codable {
		typealias NFTData = GatewayAPI.ProgrammaticScryptoSborValueTuple
		let id: NonFungibleGlobalId
		let data: NFTData?
	}

	struct AccountNonFungibleIdsPage: Sendable, Hashable, Codable {
		let accountAddress: AccountAddress
		let resourceAddress: ResourceAddress
		let ids: [NonFungibleGlobalId]
		let pageCursor: String?
		let nextPageCursor: String?
	}
}

extension OnLedgerEntity {
	struct ResourcePool: Sendable, Hashable, Codable {
		let address: PoolAddress
		let poolUnitResourceAddress: ResourceAddress
		let resources: OwnedFungibleResources
		let metadata: Metadata
	}

	struct Validator: Sendable, Hashable, Codable {
		let address: ValidatorAddress
		let stakeUnitResourceAddress: ResourceAddress
		let xrdVaultBalance: Decimal192
		let stakeClaimFungibleResourceAddress: ResourceAddress
		let metadata: Metadata
	}
}

extension OnLedgerEntity {
	struct OwnedFungibleResources: Sendable, Hashable, Codable, CustomDebugStringConvertible {
		var xrdResource: OwnedFungibleResource?
		var nonXrdResources: [OwnedFungibleResource]

		init(
			xrdResource: OwnedFungibleResource? = nil,
			nonXrdResources: [OwnedFungibleResource] = []
		) {
			if let xrdResource {
				precondition(xrdResource.resourceAddress.isXRD, "non XRD address used as XRD!")
			}
			precondition(nonXrdResources.allSatisfy { !$0.resourceAddress.isXRD }, "XRD found in non XRD!")
			self.xrdResource = xrdResource
			self.nonXrdResources = nonXrdResources
		}

		var debugDescription: String {
			let xrd = xrdResource?.debugDescription ?? ""
			let nonXRD = nonXrdResources.map(\.debugDescription).joined(separator: "\n")
			return [
				xrd.nilIfEmpty,
				nonXRD.nilIfEmpty,
			].compactMap { $0 }.joined(separator: "\n")
		}
	}

	struct OwnedFungibleResource: Sendable, Hashable, Identifiable, Codable, CustomDebugStringConvertible {
		var id: ResourceAddress {
			resourceAddress
		}

		let resourceAddress: ResourceAddress
		let atLedgerState: AtLedgerState
		var amount: ResourceAmount
		let metadata: Metadata

		var debugDescription: String {
			let symbol: String = metadata.symbol ?? "???"

			return "\(symbol) - \(resourceAddress.formatted()) | # \(amount.nominalAmount.formatted())"
		}

		init(
			resourceAddress: ResourceAddress,
			atLedgerState: AtLedgerState,
			amount: ResourceAmount,
			metadata: Metadata
		) {
			self.resourceAddress = resourceAddress
			self.atLedgerState = atLedgerState
			self.amount = amount
			self.metadata = metadata
		}
	}

	struct OwnedNonFungibleResource: Sendable, Hashable, Identifiable, Codable, CustomDebugStringConvertible {
		var id: ResourceAddress {
			resourceAddress
		}

		var debugDescription: String {
			"""
			\(resourceAddress.formatted())
			localID count: #\(nonFungibleIdsCount)
			"""
		}

		let resourceAddress: ResourceAddress
		let atLedgerState: AtLedgerState
		let metadata: Metadata
		var nonFungibleIdsCount: Int
		/// The vault where the owned ids are stored
		let vaultAddress: VaultAddress

		init(
			resourceAddress: ResourceAddress,
			atLedgerState: AtLedgerState,
			metadata: Metadata,
			nonFungibleIdsCount: Int,
			vaultAddress: VaultAddress
		) {
			self.resourceAddress = resourceAddress
			self.atLedgerState = atLedgerState
			self.metadata = metadata
			self.nonFungibleIdsCount = nonFungibleIdsCount
			self.vaultAddress = vaultAddress
		}
	}
}

// MARK: - GatewayAPI.DepositRule
extension GatewayAPI {
	enum DepositRule: String, Sendable, Hashable, Codable {
		case accept = "Accept"
		case reject = "Reject"
		case allowExisting = "AllowExisting"
	}
}

extension DepositRule {
	init(gateway: GatewayAPI.DepositRule) {
		switch gateway {
		case .accept: self = .acceptAll
		case .reject: self = .denyAll
		case .allowExisting: self = .acceptKnown
		}
	}
}

extension OnLedgerEntity.OnLedgerAccount.Details {
	init?(_ component: GatewayAPI.StateEntityDetailsResponseComponentDetails?) {
		guard let stateAny = component?.state else {
			return nil
		}
		guard let state = stateAny.value as? [String: String] else {
			return nil
		}
		guard let gatewayDepositRaw = state["default_deposit_rule"] else {
			return nil
		}
		guard let gatewayDeposit = GatewayAPI.DepositRule(rawValue: gatewayDepositRaw) else {
			return nil
		}
		let primaryLocker = try? component?.twoWayLinkedDappDetails?.primaryLocker.map { try LockerAddress(validatingAddress: $0) }
		self.init(depositRule: .init(gateway: gatewayDeposit), primaryLocker: primaryLocker)
	}

	init?(_ details: GatewayAPI.StateEntityDetailsResponseItemDetails?) {
		self.init(details?.component)
	}

	init?(_ item: GatewayAPI.StateEntityDetailsResponseItem) {
		self.init(item.details)
	}
}

// MARK: - OnLedgerEntity.OnLedgerAccount
extension OnLedgerEntity {
	struct OnLedgerAccount: Sendable, Hashable, Codable, CustomDebugStringConvertible {
		let address: AccountAddress
		let atLedgerState: AtLedgerState
		let metadata: Metadata
		var fungibleResources: OwnedFungibleResources
		var nonFungibleResources: [OwnedNonFungibleResource]
		var poolUnitResources: PoolUnitResources

		struct Details: Sendable, Hashable, Codable {
			let depositRule: DepositRule
			let primaryLocker: LockerAddress?

			init(depositRule: DepositRule, primaryLocker: LockerAddress?) {
				self.depositRule = depositRule
				self.primaryLocker = primaryLocker
			}
		}

		var debugDescription: String {
			let fun = fungibleResources.debugDescription
			let nonFun = nonFungibleResources.map(\.debugDescription).joined(separator: "\n")
			let stakes = poolUnitResources.radixNetworkStakes.map(\.debugDescription).joined(separator: "\n")
			let pools = poolUnitResources.poolUnits.map(\.debugDescription).joined(separator: "\n")

			return [
				address.formatted(),
				fun.nilIfEmpty,
				nonFun.nilIfEmpty,
				stakes.nilIfEmpty,
				pools.nilIfEmpty,
			].compactMap { $0 }.joined(separator: "\n")
		}

		var details: Details?

		init(
			address: AccountAddress,
			atLedgerState: AtLedgerState,
			metadata: Metadata,
			fungibleResources: OwnedFungibleResources,
			nonFungibleResources: [OwnedNonFungibleResource],
			poolUnitResources: PoolUnitResources,
			details: Details? = nil
		) {
			self.address = address
			self.atLedgerState = atLedgerState
			self.metadata = metadata
			self.fungibleResources = fungibleResources
			self.nonFungibleResources = nonFungibleResources
			self.poolUnitResources = poolUnitResources
			self.details = details
		}
	}
}

// MARK: - OnLedgerEntity.AssociatedDapp
extension OnLedgerEntity {
	struct AssociatedDapp: Sendable, Hashable, Codable {
		let address: DappDefinitionAddress
		let metadata: Metadata

		init(address: DappDefinitionAddress, metadata: Metadata) {
			self.address = address
			self.metadata = metadata
		}
	}
}

extension OnLedgerEntity.OnLedgerAccount {
	struct PoolUnitResources: Sendable, Hashable, Codable {
		var radixNetworkStakes: IdentifiedArrayOf<RadixNetworkStake>
		var poolUnits: [PoolUnit]
	}

	struct RadixNetworkStake: Sendable, Hashable, Codable, Identifiable, CustomDebugStringConvertible {
		var id: ValidatorAddress {
			validatorAddress
		}

		var debugDescription: String {
			"""
			\(validatorAddress.formatted())
			staked: \(stakeUnitResource?.amount.nominalAmount.formatted() ?? "NONE")
			claimable?: \(stakeClaimResource != nil)
			"""
		}

		let validatorAddress: ValidatorAddress
		var stakeUnitResource: OnLedgerEntity.OwnedFungibleResource?
		let stakeClaimResource: OnLedgerEntity.OwnedNonFungibleResource?

		init(
			validatorAddress: ValidatorAddress,
			stakeUnitResource: OnLedgerEntity.OwnedFungibleResource?,
			stakeClaimResource: OnLedgerEntity.OwnedNonFungibleResource?
		) {
			self.validatorAddress = validatorAddress
			self.stakeUnitResource = stakeUnitResource
			self.stakeClaimResource = stakeClaimResource
		}
	}

	struct PoolUnit: Sendable, Hashable, Codable, CustomDebugStringConvertible {
		let resource: OnLedgerEntity.OwnedFungibleResource
		let resourcePoolAddress: PoolAddress
		let poolResources: [ResourceAddress]

		var descriptionOfPoolKind: String {
			String(describing: resourcePoolAddress.poolKind)
		}

		var debugDescription: String {
			"""
			\(resourcePoolAddress.formatted())
			kind: \(descriptionOfPoolKind)
			amount: \(resource.amount.nominalAmount.formatted())
			"""
		}

		init(
			resource: OnLedgerEntity.OwnedFungibleResource,
			resourcePoolAddress: PoolAddress,
			poolResources: [ResourceAddress] = []
		) {
			self.resource = resource
			self.resourcePoolAddress = resourcePoolAddress
			self.poolResources = poolResources
		}
	}
}

// MARK: - OnLedgerEntity.NonFungibleToken.NFTData
extension OnLedgerEntity.NonFungibleToken.NFTData {
	enum StandardField: String, Sendable, Hashable, Codable, CaseIterable {
		case name
		case description
		case keyImageURL = "key_image_url"
		case claimEpoch = "claim_epoch"
		case claimAmount = "claim_amount"
	}

	func getString(forField field: StandardField) -> String? {
		self.fields.compactMap(/GatewayAPI.ProgrammaticScryptoSborValue.string).first {
			$0.fieldName == field.rawValue
		}?.value
	}

	func getU64Value(forField field: StandardField) -> UInt64? {
		for f in fields {
			if case let .u64(u64) = f, u64.fieldName == field.rawValue {
				return UInt64(u64.value)
			}
		}
		return nil
	}

	func getDecimalValue(forField field: StandardField) -> Decimal192? {
		self.fields
			.compactMap(/GatewayAPI.ProgrammaticScryptoSborValue.decimal)
			.first { $0.fieldName == field.rawValue }
			.flatMap { try? Decimal192($0.value) }
	}

	var name: String? {
		getString(forField: .name)
	}

	var tokenDescription: String? {
		getString(forField: .description)
	}

	var keyImageURL: URL? {
		getString(forField: .keyImageURL).flatMap(URL.init(string:))
	}

	var claimAmount: Decimal192? {
		getDecimalValue(forField: .claimAmount)
	}

	var claimEpoch: UInt64? {
		getU64Value(forField: .claimEpoch)
	}
}

extension OnLedgerEntity.OnLedgerAccount {
	var allFungibleResourceAddresses: [ResourceAddress] {
		fungibleResources.xrdResource.asArray(\.resourceAddress) + fungibleResources.nonXrdResources.map(\.resourceAddress)
	}

	var allResourceAddresses: Set<ResourceAddress> {
		Set(
			allFungibleResourceAddresses
				+ nonFungibleResources.map(\.resourceAddress)
				+ poolUnitResources.fungibleResourceAddresses
				+ poolUnitResources.nonFungibleResourceAddresses
		)
	}

	func hasResource(_ resourceAddress: ResourceAddress) -> Bool {
		allResourceAddresses.contains(resourceAddress)
	}
}

extension OnLedgerEntity.Resource {
	func poolRedemptionValue(
		for amount: Decimal192,
		poolUnitResource: OnLedgerEntitiesClient.ResourceWithVaultAmount
	) -> Decimal192? {
		guard let poolUnitTotalSupply = poolUnitResource.resource.totalSupply else {
			loggerGlobal.error("Missing total supply for \(poolUnitResource.resource.resourceAddress.address)")
			return nil
		}
		guard poolUnitTotalSupply > 0 else {
			loggerGlobal.error("Total supply is 0 for \(poolUnitResource.resource.resourceAddress.address)")
			return nil
		}
		let redemptionValue = poolUnitResource.amount.nominalAmount * (amount / poolUnitTotalSupply)
		let decimalPlaces = divisibility ?? Decimal192.maxDivisibility
		let roundedRedemptionValue = redemptionValue.rounded(decimalPlaces: decimalPlaces)

		return roundedRedemptionValue
	}
}

extension OnLedgerEntity.Resource {
	var fungibleResourceName: String? {
		metadata.title
	}
}
