import Foundation

// MARK: - AccountLockerClaimDetails
/// A struct holding the details for the pending claims of a given locker address & account address.
struct AccountLockerClaimDetails: Sendable, Hashable, Codable {
	let lockerAddress: LockerAddress
	let accountAddress: AccountAddress
	let dappDefinitionAddress: DappDefinitionAddress
	let dappName: String?
	let lastTouchedAtStateVersion: AtStateVersion
	let claims: [Claim]
}

// MARK: AccountLockerClaimDetails.Claim
extension AccountLockerClaimDetails {
	enum Claim: Sendable, Hashable, Codable {
		case fungible(Fungible)
		case nonFungible(NonFungible)
	}
}

extension AccountLockerClaimDetails.Claim {
	struct Fungible: Sendable, Hashable, Codable {
		let resourceAddress: ResourceAddress
		let amount: Decimal192
	}

	struct NonFungible: Sendable, Hashable, Codable {
		let resourceAddress: ResourceAddress
		let count: Int
	}
}

extension AccountLockerClaimDetails.Claim {
	init(_ item: GatewayAPI.AccountLockerVaultCollectionItem) throws {
		switch item {
		case let .fungible(value):
			let resourceAddress = try ResourceAddress(validatingAddress: value.resourceAddress)
			let amount = try Decimal192(value.amount)
			self = .fungible(.init(resourceAddress: resourceAddress, amount: amount))

		case let .nonFungible(value):
			let resourceAddress = try ResourceAddress(validatingAddress: value.resourceAddress)
			let count = Int(value.totalCount)
			self = .nonFungible(.init(resourceAddress: resourceAddress, count: count))
		}
	}
}
