import ClientPrelude

// MARK: - MakeTransactionHeaderInput
public struct MakeTransactionHeaderInput: Sendable, Hashable {
	public var epochWindow: Epoch
	public var costUnitLimit: UInt32
	public var tipPercentage: UInt16

	public init(
		epochWindow: Epoch = 10,
		costUnitLimit: UInt32 = 100_000_000,
		tipPercentage: UInt16 = 0
	) {
		self.epochWindow = epochWindow
		self.costUnitLimit = costUnitLimit
		self.tipPercentage = tipPercentage
	}
}

extension MakeTransactionHeaderInput {
	public static let `default` = Self()
}
