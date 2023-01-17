import ClientPrelude

// MARK: - MakeTransactionHeaderInput
public struct MakeTransactionHeaderInput: Sendable, Hashable {
	public var epochWindow: Epoch
	public var costUnitLimit: UInt32
	public var tipPercentage: UInt8

	public init(
		epochWindow: Epoch = 10,
		costUnitLimit: UInt32 = 100_000_000,
		tipPercentage: UInt8 = 0
	) {
		self.epochWindow = epochWindow
		self.costUnitLimit = costUnitLimit
		self.tipPercentage = tipPercentage
	}
}

public extension MakeTransactionHeaderInput {
	static let `default` = Self()
}
