import EngineToolkit

// MARK: - MakeTransactionHeaderInput
public struct MakeTransactionHeaderInput: Sendable, Hashable {
	public var epochWindow: Epoch
	public var costUnitLimit: UInt32
	public var tipPercentage: UInt32

	public init(
		epochWindow: Epoch = 10,
		costUnitLimit: UInt32 = 10_000_000,
		tipPercentage: UInt32 = 0
	) {
		self.epochWindow = epochWindow
		self.costUnitLimit = costUnitLimit
		self.tipPercentage = tipPercentage
	}
}

public extension MakeTransactionHeaderInput {
	static let `default` = Self()
}
