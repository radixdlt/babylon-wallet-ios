import ChooseLedgerHardwareDeviceFeature
import DerivePublicKeysFeature
import FeaturePrelude

extension CreationOfAccount {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreationOfAccount>

		public init(store: StoreOf<CreationOfAccount>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ZStack {
				SwitchStore(store.scope(state: \.step)) {
					CaseLet(
						state: /CreationOfAccount.State.Step.step0_chooseLedger,
						action: { CreationOfAccount.Action.child(.step0_chooseLedger($0)) },
						then: { ChooseLedgerHardwareDevice.View(store: $0) }
					)
					CaseLet(
						state: /CreationOfAccount.State.Step.step1_derivePublicKeys,
						action: { CreationOfAccount.Action.child(.step1_derivePublicKeys($0)) },
						then: { DerivePublicKeys.View(store: $0) }
					)
				}
			}
			.navigationTitle(L10n.CreateEntity.Ledger.createAccount)
			.onFirstTask { @MainActor in
				ViewStore(store.stateless).send(.view(.onFirstTask))
			}
		}
	}
}
