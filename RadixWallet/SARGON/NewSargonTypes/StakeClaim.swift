import Foundation

public struct StakeClaim: Sendable {
	public let validatorAddress: ValidatorAddress
	public let resourceAddress: ResourceAddress
	public let ids: NonEmpty<[NonFungibleLocalId]>
	/// The summed claim amount across ids
	public let amount: RETDecimal
}
