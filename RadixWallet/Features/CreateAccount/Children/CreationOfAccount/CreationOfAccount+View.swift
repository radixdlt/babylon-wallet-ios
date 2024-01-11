import ComposableArchitecture
import SwiftUI

extension CreationOfAccount {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreationOfAccount>

		public init(store: StoreOf<CreationOfAccount>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ZStack {
				SwitchStore(store.scope(state: \.step, action: Action.child)) { state in
					switch state {
					case .step0_chooseLedger:
						CaseLet(
							/CreationOfAccount.State.Step.step0_chooseLedger,
							action: CreationOfAccount.ChildAction.step0_chooseLedger,
							then: { LedgerHardwareDevices.View(store: $0) }
						)
					case .step1_derivePublicKeys:
						CaseLet(
							/CreationOfAccount.State.Step.step1_derivePublicKeys,
							action: CreationOfAccount.ChildAction.step1_derivePublicKeys,
							then: { DerivePublicKeys.View(store: $0) }
						)
					}
				}
			}
			.navigationBarTitleColor(.app.gray1)
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarInlineTitleFont(.app.secondaryHeader)
		}
	}
}
