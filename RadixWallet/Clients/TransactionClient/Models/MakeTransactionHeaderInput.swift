// MARK: - MakeTransactionHeaderInput
struct MakeTransactionHeaderInput: Sendable, Hashable {
	var epochWindow: Epoch
	var costUnitLimit: UInt32
	var tipPercentage: UInt16

	init(
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
	static let `default` = Self()
}
