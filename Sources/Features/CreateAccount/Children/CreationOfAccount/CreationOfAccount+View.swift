import ChooseLedgerHardwareDeviceFeature
import DerivePublicKeyFeature
import FeaturePrelude

extension CreationOfAccount {
	public struct ViewState: Equatable {
		let useLedgerAsFactorSource: Bool

		init(state: CreationOfAccount.State) {
			useLedgerAsFactorSource = false
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreationOfAccount>

		public init(store: StoreOf<CreationOfAccount>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: CreationOfAccount.ViewState.init(state:),
				send: { .view($0) }
			) { _ in
				ZStack {
					SwitchStore(store.scope(state: \.step)) {
						CaseLet(
							state: /CreationOfAccount.State.Step.step0_chooseLedger,
							action: { CreationOfAccount.Action.child(.step0_chooseLedger($0)) },
							then: { ChooseLedgerHardwareDevice.View(store: $0) }
						)
						CaseLet(
							state: /CreationOfAccount.State.Step.step1_derivePublicKey,
							action: { CreationOfAccount.Action.child(.step1_derivePublicKey($0)) },
							then: { DerivePublicKey.View(store: $0) }
						)
					}
				}
				.onFirstTask { @MainActor in
					ViewStore(store.stateless).send(.view(.onFirstTask))
				}
			}
		}
	}
}

extension CreationOfAccount.ViewState {
	var navigationTitle: String {
		L10n.CreateEntity.Ledger.createAccount
	}
}
