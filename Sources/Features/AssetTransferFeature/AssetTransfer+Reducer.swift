import FeaturePrelude
import TransactionSigningFeature

// MARK: - AssetTransfer
public struct AssetTransfer: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public typealias From = OnNetwork.Account

		// TODO: declare union type for this in SharedModels
		public enum AssetToTransfer: Sendable, Hashable {
			case token(FungibleToken)
//			case nft(NonFungibleToken)
		}

		public enum To: Sendable, Hashable {
//			case account(OnNetwork.Account)
			case address(AccountAddress)

			var address: AccountAddress {
				switch self {
				case let .address(address):
					return address
				}
			}
		}

		public let from: From
		public var asset: AssetToTransfer
		public var amount: Decimal_?
		public var to: To?

		@PresentationStateOf<Destinations>
		public var destination

		public init(
			from: From,
			asset: AssetToTransfer,
			amount: Decimal_? = nil,
			to: To? = nil
		) {
			self.from = from
			self.asset = asset
			self.amount = amount
			self.to = to
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case amountTextFieldChanged(String)
		case toAddressTextFieldChanged(String)
		case nextButtonTapped(amount: Decimal_, toAddress: AccountAddress)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationActionOf<AssetTransfer.Destinations>)
	}

	public struct Destinations: ReducerProtocol {
		public enum State: Hashable {
			case transactionSigning(TransactionSigning.State)
		}

		public enum Action: Equatable {
			case transactionSigning(TransactionSigning.Action)
		}

		public var body: some ReducerProtocol<State, Action> {
			Scope(state: /State.transactionSigning, action: /Action.transactionSigning) {
				TransactionSigning()
			}
		}
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. Action.ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .amountTextFieldChanged(amount):
			if let amount = amount.nilIfBlank {
				state.amount = .init(value: amount)
			} else {
				state.amount = nil
			}
			return .none
		case let .toAddressTextFieldChanged(address):
			if let address = try? AccountAddress(address: address) {
				state.to = .address(address)
			} else {
				state.to = nil
			}
			return .none
		case let .nextButtonTapped(amount, toAddress):
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
		}
	}
}
