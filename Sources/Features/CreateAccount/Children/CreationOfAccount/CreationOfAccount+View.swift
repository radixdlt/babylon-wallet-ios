import ChooseLedgerHardwareDeviceFeature
import DerivePublicKeyFeature
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
						state: /CreationOfAccount.State.Step.step1_derivePublicKey,
						action: { CreationOfAccount.Action.child(.step1_derivePublicKey($0)) },
						then: { DerivePublicKey.View(store: $0) }
					)
				}
			}
			.navigationTitle(L10n.CreateEntity.Ledger.createAccount)
			#if os(iOS)
				.navigationBarTitleColor(.app.gray1)
				.navigationBarTitleDisplayMode(.inline)
				.navigationBarInlineTitleFont(.app.secondaryHeader)
			#endif
				.onFirstTask { @MainActor in
					ViewStore(store.stateless).send(.view(.onFirstTask))
				}
		}
	}
}
