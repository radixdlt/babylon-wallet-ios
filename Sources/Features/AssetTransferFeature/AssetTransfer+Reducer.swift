import FeaturePrelude

public struct AssetTransfer: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):
			return .none
		case let .internal(.view(.amountTextFieldChanged(amount))):
			state.amount = .init(value: amount)
			return .none
		case let .internal(.view(.toAddressTextFieldChanged(address))):
			if let address = try? AccountAddress(address: address) {
				state.to = .address(address)
			}
			return .none
		case .internal(.view(.nextButtonTapped)):
			return .none
		}
	}
}
