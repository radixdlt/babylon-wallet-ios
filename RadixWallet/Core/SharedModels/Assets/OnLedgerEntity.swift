// MARK: - OnLedgerEntity
public enum OnLedgerEntity: Sendable, Hashable, Codable, CustomDebugStringConvertible {
	public var debugDescription: String {
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
		}
	}

	case resource(Resource)
	case account(Account)
	case resourcePool(ResourcePool)
	case validator(Validator)
	case nonFungibleToken(NonFungibleToken)
	case accountNonFungibleIds(AccountNonFungibleIdsPage)
	case genericComponent(GenericComponent)

	public var resource: Resource? {
		guard case let .resource(resource) = self else {
			return nil
		}
		return resource
	}

	public var nonFungibleToken: NonFungibleToken? {
		guard case let .nonFungibleToken(nonFungibleToken) = self else {
			return nil
		}
		return nonFungibleToken
	}

	public var accountNonFungibleIds: AccountNonFungibleIdsPage? {
		guard case let .accountNonFungibleIds(ids) = self else {
			return nil
		}
		return ids
	}

	public var account: Account? {
		guard case let .account(account) = self else {
			return nil
		}
		return account
	}

	public var resourcePool: ResourcePool? {
		guard case let .resourcePool(resourcePool) = self else {
			return nil
		}
		return resourcePool
	}

	public var validator: Validator? {
		guard case let .validator(validator) = self else {
			return nil
		}
		return validator
	}

	public var genericComponent: GenericComponent? {
		guard case let .genericComponent(genericComponent) = self else {
			return nil
		}
		return genericComponent
	}

	public var metadata: Metadata? {
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
	init(newlyCreated: Sargon.NewlyCreatedResource) {
		self.init(
			name: newlyCreated.name,
			symbol: newlyCreated.symbol,
			description: newlyCreated.description,
			iconURL: newlyCreated.iconUrl.map { URL(string: $0) } ?? nil,
			tags: newlyCreated.tags.compactMap(NonEmptyString.init(rawValue:)).map(AssetTag.custom)
		)
	}
}

extension OnLedgerEntity {
	public struct Metadata: Sendable, Hashable, Codable {
		public enum PublicKeyHash: Sendable, Hashable, Codable {
			case ecdsaSecp256k1(String)
			case eddsaEd25519(String)
		}

		public let name: String?
		public let symbol: String?
		public let description: String?
		public let iconURL: URL?
		public let tags: [AssetTag]
		public let dappDefinitions: [AccountAddress]?
		public let dappDefinition: AccountAddress?
		public let validator: ValidatorAddress?
		public let poolUnit: PoolAddress?
		public let poolUnitResource: ResourceAddress?
		public let claimedEntities: [String]?
		public let claimedWebsites: [URL]?
		public let accountType: AccountType?
		public let ownerKeys: PublicKeyHashesWithStateVersion?
		public let ownerBadge: OwnerBadgeWithStateVersion?

		public struct ValueAtStateVersion<Value>: Codable where Value: Codable {
			public let value: Value
			public let lastUpdatedAtStateVersion: AtStateVersion

			public func map<T>(_ transform: (Value) throws -> T) rethrows -> ValueAtStateVersion<T> {
				try ValueAtStateVersion<T>(
					value: transform(value),
					lastUpdatedAtStateVersion: lastUpdatedAtStateVersion
				)
			}

			public func map<T>(_ transform: (Value) throws -> T?) rethrows -> ValueAtStateVersion<T>? {
				guard let transformed = try transform(value) else { return nil }
				return ValueAtStateVersion<T>(
					value: transformed,
					lastUpdatedAtStateVersion: lastUpdatedAtStateVersion
				)
			}

			public func mapArray<T>(_ transform: (Value) throws -> [T]?) rethrows -> [ValueAtStateVersion<T>]? {
				guard let elements = try transform(value) else { return nil }
				return elements.map { (element: T) in
					ValueAtStateVersion<T>(value: element, lastUpdatedAtStateVersion: lastUpdatedAtStateVersion)
				}
			}
		}

		public typealias OwnerBadgeWithStateVersion = ValueAtStateVersion<NonFungibleLocalId>
		public typealias PublicKeyHashesWithStateVersion = ValueAtStateVersion<[PublicKeyHash]>

		public init(
			name: String? = nil,
			symbol: String? = nil,
			description: String? = nil,
			iconURL: URL? = nil,
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
			ownerBadge: OwnerBadgeWithStateVersion? = nil
		) {
			self.name = name
			self.symbol = symbol
			self.description = description
			self.iconURL = iconURL
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
		}
	}

	// MARK: - AccountType
	public enum AccountType: String, Sendable, Codable {
		case dappDefinition = "dapp definition"
	}

	public struct Resource: Sendable, Hashable, Codable, Identifiable, CustomDebugStringConvertible {
		public var id: ResourceAddress { resourceAddress }
		public let resourceAddress: ResourceAddress
		public let atLedgerState: AtLedgerState
		public let divisibility: UInt8?
		public let behaviors: [AssetBehavior]
		public let totalSupply: Decimal192?
		public let metadata: Metadata

		public var debugDescription: String {
			"""
			\(resourceAddress.formatted())
			symbol: \(metadata.symbol ?? "???")
			name: \(metadata.name ?? "???")
			icon: \(metadata.iconURL?.absoluteString ?? "???")
			description: \(metadata.description ?? "???")
			"""
		}

		public var fungibility: Fungibility {
			if resourceAddress.isFungible {
				.fungible
			} else {
				.nonFungible
			}
		}

		public enum Fungibility {
			case fungible
			case nonFungible
		}

		public init(
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

	public struct GenericComponent: Sendable, Hashable, Codable {
		public let address: ComponentAddress
		public let atLedgerState: AtLedgerState
		public let behaviors: [AssetBehavior]
		public let metadata: Metadata
	}
}

extension OnLedgerEntity {
	public struct NonFungibleToken: Sendable, Hashable, Identifiable, Codable {
		public typealias NFTData = GatewayAPI.ProgrammaticScryptoSborValueTuple
		public let id: NonFungibleGlobalId
		public let data: NFTData?
	}

	public struct AccountNonFungibleIdsPage: Sendable, Hashable, Codable {
		public let accountAddress: AccountAddress
		public let resourceAddress: ResourceAddress
		public let ids: [NonFungibleGlobalId]
		public let pageCursor: String?
		public let nextPageCursor: String?
	}
}

extension OnLedgerEntity {
	public struct ResourcePool: Sendable, Hashable, Codable {
		public let address: PoolAddress
		public let poolUnitResourceAddress: ResourceAddress
		public let resources: OwnedFungibleResources
		public let metadata: Metadata
	}

	public struct Validator: Sendable, Hashable, Codable {
		public let address: ValidatorAddress
		public let stakeUnitResourceAddress: ResourceAddress
		public let xrdVaultBalance: Decimal192
		public let stakeClaimFungibleResourceAddress: ResourceAddress
		public let metadata: Metadata
	}
}

extension OnLedgerEntity {
	public struct OwnedFungibleResources: Sendable, Hashable, Codable, CustomDebugStringConvertible {
		public var xrdResource: OwnedFungibleResource?
		public var nonXrdResources: [OwnedFungibleResource]

		public init(
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

		public var debugDescription: String {
			let xrd = xrdResource?.debugDescription ?? ""
			let nonXRD = nonXrdResources.map(\.debugDescription).joined(separator: "\n")
			return [
				xrd.nilIfEmpty,
				nonXRD.nilIfEmpty,
			].compactMap { $0 }.joined(separator: "\n")
		}
	}

	public struct OwnedFungibleResource: Sendable, Hashable, Identifiable, Codable, CustomDebugStringConvertible {
		public var id: ResourceAddress {
			resourceAddress
		}

		public let resourceAddress: ResourceAddress
		public let atLedgerState: AtLedgerState
		public var amount: ResourceAmount
		public let metadata: Metadata

		public var debugDescription: String {
			let symbol: String = metadata.symbol ?? "???"

			return "\(symbol) - \(resourceAddress.formatted()) | # \(amount.nominalAmount.formatted())"
		}

		public init(
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

	public struct OwnedNonFungibleResource: Sendable, Hashable, Identifiable, Codable, CustomDebugStringConvertible {
		public var id: ResourceAddress {
			resourceAddress
		}

		public var debugDescription: String {
			"""
			\(resourceAddress.formatted())
			localID count: #\(nonFungibleIdsCount)
			"""
		}

		public let resourceAddress: ResourceAddress
		public let atLedgerState: AtLedgerState
		public let metadata: Metadata
		public let nonFungibleIdsCount: Int
		/// The vault where the owned ids are stored
		public let vaultAddress: VaultAddress

		public init(
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
	public enum DepositRule: String, Sendable, Hashable, Codable {
		case accept = "Accept"
		case reject = "Reject"
		case allowExisting = "AllowExisting"
	}
}

extension Profile.Network.Account.OnLedgerSettings.ThirdPartyDeposits.DepositRule {
	public init(gateway: GatewayAPI.DepositRule) {
		switch gateway {
		case .accept: self = .acceptAll
		case .reject: self = .denyAll
		case .allowExisting: self = .acceptKnown
		}
	}
}

extension OnLedgerEntity.Account.Details {
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
		self.init(depositRule: .init(gateway: gatewayDeposit))
	}

	init?(_ details: GatewayAPI.StateEntityDetailsResponseItemDetails?) {
		self.init(details?.component)
	}

	init?(_ item: GatewayAPI.StateEntityDetailsResponseItem) {
		self.init(item.details)
	}
}

// MARK: - OnLedgerEntity.Account
extension OnLedgerEntity {
	public struct Account: Sendable, Hashable, Codable, CustomDebugStringConvertible {
		public let address: AccountAddress
		public let atLedgerState: AtLedgerState
		public let metadata: Metadata
		public var fungibleResources: OwnedFungibleResources
		public var nonFungibleResources: [OwnedNonFungibleResource]
		public var poolUnitResources: PoolUnitResources

		public struct Details: Sendable, Hashable, Codable {
			public let depositRule: Profile.Network.Account.OnLedgerSettings.ThirdPartyDeposits.DepositRule
			public init(depositRule: Profile.Network.Account.OnLedgerSettings.ThirdPartyDeposits.DepositRule) {
				self.depositRule = depositRule
			}
		}

		public var debugDescription: String {
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

		public var details: Details?

		public init(
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
	public struct AssociatedDapp: Sendable, Hashable, Codable {
		public let address: DappDefinitionAddress
		public let metadata: Metadata

		public init(address: DappDefinitionAddress, metadata: Metadata) {
			self.address = address
			self.metadata = metadata
		}
	}
}

extension OnLedgerEntity.Account {
	public struct PoolUnitResources: Sendable, Hashable, Codable {
		public var radixNetworkStakes: IdentifiedArrayOf<RadixNetworkStake>
		public let poolUnits: [PoolUnit]
	}

	public struct RadixNetworkStake: Sendable, Hashable, Codable, Identifiable, CustomDebugStringConvertible {
		public var id: ValidatorAddress {
			validatorAddress
		}

		public var debugDescription: String {
			"""
			\(validatorAddress.formatted())
			staked: \(stakeUnitResource?.amount.nominalAmount.formatted() ?? "NONE")
			claimable?: \(stakeClaimResource != nil)
			"""
		}

		public let validatorAddress: ValidatorAddress
		public var stakeUnitResource: OnLedgerEntity.OwnedFungibleResource?
		public let stakeClaimResource: OnLedgerEntity.OwnedNonFungibleResource?

		public init(
			validatorAddress: ValidatorAddress,
			stakeUnitResource: OnLedgerEntity.OwnedFungibleResource?,
			stakeClaimResource: OnLedgerEntity.OwnedNonFungibleResource?
		) {
			self.validatorAddress = validatorAddress
			self.stakeUnitResource = stakeUnitResource
			self.stakeClaimResource = stakeClaimResource
		}
	}

	public struct PoolUnit: Sendable, Hashable, Codable, CustomDebugStringConvertible {
		public let resource: OnLedgerEntity.OwnedFungibleResource
		public let resourcePoolAddress: PoolAddress
		public let poolResources: [ResourceAddress]

		public var descriptionOfPoolKind: String {
			String(describing: resourcePoolAddress.poolKind)
		}

		public var debugDescription: String {
			"""
			\(resourcePoolAddress.formatted())
			kind: \(descriptionOfPoolKind)
			amount: \(resource.amount.nominalAmount.formatted())
			"""
		}

		public init(
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
	public enum StandardField: String, Sendable, Hashable, Codable, CaseIterable {
		case name
		case description
		case keyImageURL = "key_image_url"
		case claimEpoch = "claim_epoch"
		case claimAmount = "claim_amount"
	}

	public func getString(forField field: StandardField) -> String? {
		self.fields.compactMap(/GatewayAPI.ProgrammaticScryptoSborValue.string).first {
			$0.fieldName == field.rawValue
		}?.value
	}

	public func getU64Value(forField field: StandardField) -> UInt64? {
		for f in fields {
			if case let .u64(u64) = f, u64.fieldName == field.rawValue {
				return UInt64(u64.value)
			}
		}
		return nil
	}

	public func getDecimalValue(forField field: StandardField) -> Decimal192? {
		self.fields
			.compactMap(/GatewayAPI.ProgrammaticScryptoSborValue.decimal)
			.first { $0.fieldName == field.rawValue }
			.flatMap { try? Decimal192($0.value) }
	}

	public var name: String? {
		getString(forField: .name)
	}

	public var tokenDescription: String? {
		getString(forField: .description)
	}

	public var keyImageURL: URL? {
		getString(forField: .keyImageURL).flatMap(URL.init(string:))
	}

	public var claimAmount: Decimal192? {
		getDecimalValue(forField: .claimAmount)
	}

	public var claimEpoch: UInt64? {
		getU64Value(forField: .claimEpoch)
	}
}

extension OnLedgerEntity.Account {
	public var allFungibleResourceAddresses: [ResourceAddress] {
		fungibleResources.xrdResource.asArray(\.resourceAddress) + fungibleResources.nonXrdResources.map(\.resourceAddress)
	}

	public var allResourceAddresses: Set<ResourceAddress> {
		Set(
			allFungibleResourceAddresses
				+ nonFungibleResources.map(\.resourceAddress)
				+ poolUnitResources.fungibleResourceAddresses
				+ poolUnitResources.nonFungibleResourceAddresses
		)
	}

	public func hasResource(_ resourceAddress: ResourceAddress) -> Bool {
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
	public var fungibleResourceName: String? {
		metadata.fungibleResourceName
	}
}

extension OnLedgerEntity.Metadata {
	public var fungibleResourceName: String? {
		name ?? symbol
	}
}
