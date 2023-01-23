import FeaturePrelude

// MARK: - GatherFactors.View
public extension GatherFactors {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<GatherFactors>

		public init(store: StoreOf<GatherFactors>) {
			self.store = store
		}
	}
}

public extension GatherFactors.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				VStack {
					NavigationBar(
						titleText: viewStore.purpose.display,
						leadingItem:
						Text("\(viewStore.index + 1)/\(viewStore.factorCount)")
							.padding(),

						trailingItem:
						Button(viewStore.isLast ? "Finish" : "Next") {
							viewStore.send(.proceed)
						}
						.buttonStyle(.primaryText())
						.controlState(viewStore.canProceed ? .enabled : .disabled)
						.padding()
					)
					ForceFullScreen {
						GatherFactor.View(
							store: store.scope(
								state: \.currentFactor,
								action: { .child(.gatherFactor($0)) }
							)
						)
					}
				}
			}
		}
	}
}

// MARK: - GatherFactors.View.ViewState
extension GatherFactors.View {
	struct ViewState: Equatable {
		public var factorCount: Int
		public var index: Int
		public var purpose: GatherFactorPurpose
		public var isLast: Bool { index == factorCount - 1 }
		public var canProceed: Bool
		init(state: GatherFactors.State) {
			purpose = state.purpose
			index = state.index
			factorCount = state.gatherFactors.count
			canProceed = state.canProceed
		}
	}
}

extension GatherFactorPurpose {
	var display: String {
		switch self {
		case .derivePublicKey(.createAccount):
			return "Derive PubKey: Create Account"
		case .derivePublicKey(.createPersona):
			return "Derive PubKey: Create Persona"
		case let .sign(toSign):
			switch toSign.mode {
			case .proofOfOwnership:
				return "Sign Proof of ownership"
			case .transaction(.fromDapp):
				return "Sign TX: From Dapp"
			case .transaction(.fromFallet(.faucet)):
				return "Sign TX: Use faucet"
			case .transaction(.fromFallet(.transfer)):
				return "Sign TX: Transfer"
			case .transaction(.fromFallet(.securitize(.account))):
				return "Sign TX: Securitize account"
			case .transaction(.fromFallet(.securitize(.persona))):
				return "Sign TX: Securitize persona"
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - GatherFactors_Preview
struct GatherFactors_Preview: PreviewProvider {
	static var previews: some View {
		GatherFactors.View(
			store: .init(
				initialState: .previewValue,
				reducer: GatherFactors()
			)
		)
	}
}
#endif
