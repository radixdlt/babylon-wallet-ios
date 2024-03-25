import Foundation

public struct TransactionGuarantee: Sendable, Hashable {
	public var amount: Decimal192
	public var instructionIndex: UInt64
	public var resourceAddress: ResourceAddress
	public var resourceDivisibility: Int?

	public init(
		amount: Decimal192,
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
