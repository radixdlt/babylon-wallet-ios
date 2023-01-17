import FeaturePrelude

// MARK: - AssetTransfer
public struct AssetTransfer: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$destination, action: /Action.child .. Action.ChildAction.destination) {
				Destinations()
			}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):
			return .none
		case let .internal(.view(.amountTextFieldChanged(amount))):
			if let amount = amount.nilIfBlank {
				state.amount = .init(value: amount)
			} else {
				state.amount = nil
			}
			return .none
		case let .internal(.view(.toAddressTextFieldChanged(address))):
			if let address = try? AccountAddress(address: address) {
				state.to = .address(address)
			} else {
				state.to = nil
			}
			return .none
		case let .internal(.view(.nextButtonTapped(amount, toAddress))):
			let manifest = TransactionManifest(instructions: .string(
				"""
				# Withdrawing 100 XRD from the account component
				CALL_METHOD
					ComponentAddress("\(state.from.address.address)")
					"withdraw_by_amount"
					Decimal("\(amount.value)")
					ResourceAddress("\(FungibleToken.xrd.componentAddress.address)");

				# Depositing all of the XRD withdrawn from the account into the other account
				CALL_METHOD
					ComponentAddress("\(toAddress.address)")
					"deposit_batch"
					Expression("ENTIRE_WORKTOP");
				"""
			))
			state.destination = .transactionSigning(.init(origin: .local(manifest: manifest)))
			return .none
		case .child:
			return .none
		}
	}
}

// MARK: - AssetTransferError
public enum AssetTransferError: LocalizedError {
	case amountRequired
	case toAddressRequired

	public var errorDescription: String? {
		switch self {
		case .amountRequired:
			return "Please enter a valid amount"
		case .toAddressRequired:
			return "Please enter a valid destination address"
		}
	}
}
