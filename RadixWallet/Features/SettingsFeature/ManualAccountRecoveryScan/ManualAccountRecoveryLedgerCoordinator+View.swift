import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoveryLedgerCoordinator.View
extension ManualAccountRecoveryLedgerCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension ManualAccountRecoveryLedgerCoordinator.View {
	public var body: some View {
		NavigationStackStore(
			store.scope(state: \.path, action: { .child(.path($0)) })
		) {
			Color.pink
				.toolbar {
					ToolbarItem(placement: .automatic) {
						CloseButton {
							store.send(.view(.closeButtonTapped))
						}
					}
				}
		} destination: {
			PathView(store: $0)
		}
	}
}

// MARK: - ManualAccountRecoveryLedgerCoordinator.View.PathView
private extension ManualAccountRecoveryLedgerCoordinator.View {
	struct PathView: View {
		let store: StoreOf<ManualAccountRecoveryLedgerCoordinator.Path>

		var body: some View {
			Color.red
//			SwitchStore(store) { state in
//				switch state {
//				case .chooseSeedPhrase:
//					CaseLet(
//						/ManualAccountRecoveryScanCoordinator.Path.State.chooseSeedPhrase,
//						action: ManualAccountRecoveryScanCoordinator.Path.Action.chooseSeedPhrase,
//						then: { ManualAccountRecoveryScanCoordinator.ChooseSeedPhrase.View(store: $0) }
//					)
//				case .chooseLedger:
//					CaseLet(
//						/ManualAccountRecoveryScanCoordinator.Path.State.chooseLedger,
//						action: ManualAccountRecoveryScanCoordinator.Path.Action.chooseLedger,
//						then: { ManualAccountRecoveryScanCoordinator.ChooseLedger.View(store: $0) }
//					)
//				}
//			}
		}
	}
}
