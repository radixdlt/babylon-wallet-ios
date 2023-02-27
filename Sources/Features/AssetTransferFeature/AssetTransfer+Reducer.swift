import FeaturePrelude
import TransactionSigningFeature

// MARK: - AssetTransfer
public struct AssetTransfer: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. Action.ChildAction.destination) {
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
			// FIXME: Cyon commented this out because `AssetTransfer` is not used for Betanet v2
			// and code below does not compile in `RELEASE` since `xrd` does not exist anymore.
			// Correct behaviour is to use a client for this and EngineToolkits wellknownAddresses
			// method to get the component address of XRD.

//			// TODO: move somewhere more practical (like Faucet manifest)
//			let manifest = TransactionManifest(instructions: .string(
//				"""
//				CALL_METHOD
//					ComponentAddress("\(state.from.address.address)")
//					"lock_fee"
//					Decimal("10");
//
//				# Withdrawing 100 XRD from the account component
//				CALL_METHOD
//					ComponentAddress("\(state.from.address.address)")
//					"withdraw_by_amount"
//					Decimal("\(amount.value)")
//					ResourceAddress("\(FungibleToken.xrd.componentAddress.address)");
//
//				# Depositing all of the XRD withdrawn from the account into the other account
//				CALL_METHOD
//					ComponentAddress("\(toAddress.address)")
//					"deposit_batch"
//					Expression("ENTIRE_WORKTOP");
//				"""
//			))
//			state.destination = .transactionSigning(
//				TransactionSigning.State(transactionManifestWithoutLockFee: manifest)
//			)
			return .none
		case .child:
			return .none
		}
	}
}
