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
			store.scope(state: \.path) { .child(.path($0)) }
		) {
			LedgerHardwareDevices.View(
				store: store.scope(state: \.root) { .child(.root($0)) }
			)
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
			SwitchStore(store) { state in
				switch state {
				case .recoveryComplete:
					CaseLet(
						/ManualAccountRecoveryLedgerCoordinator.Path.State.recoveryComplete,
						action: ManualAccountRecoveryLedgerCoordinator.Path.Action.recoveryComplete,
						then: { ManualAccountRecoveryComplete.View(store: $0) }
					)
				}
			}
		}
	}
}
