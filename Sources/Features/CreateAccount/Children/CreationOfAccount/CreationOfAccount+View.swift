import DerivePublicKeysFeature
import FeaturePrelude
import LedgerHardwareDevicesFeature

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
						then: { LedgerHardwareDevices.View(store: $0) }
					)
					CaseLet(
						state: /CreationOfAccount.State.Step.step1_derivePublicKeys,
						action: { CreationOfAccount.Action.child(.step1_derivePublicKeys($0)) },
						then: { DerivePublicKeys.View(store: $0) }
					)
				}
			}
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
