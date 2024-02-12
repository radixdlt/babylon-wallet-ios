import Foundation

public struct TransactionGuarantee: Sendable, Hashable {
	public var amount: RETDecimal
	public var instructionIndex: UInt64
	public var resourceAddress: ResourceAddress
	public var resourceDivisibility: Int?

	public init(
		amount: RETDecimal,
		instructionIndex: UInt64,
		resourceAddress: ResourceAddress,
		resourceDivisibility: Int?
	) {
		self.amount = amount
		self.instructionIndex = instructionIndex
		self.resourceAddress = resourceAddress
		self.resourceDivisibility = resourceDivisibility
	}
}
