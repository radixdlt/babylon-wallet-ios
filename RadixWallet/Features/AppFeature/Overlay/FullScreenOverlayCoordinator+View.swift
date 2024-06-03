import ComposableArchitecture
import SwiftUI

// MARK: - FullScreenOverlayCoordinator.View
extension FullScreenOverlayCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FullScreenOverlayCoordinator>

		public init(store: StoreOf<FullScreenOverlayCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStack {
				root(for: store.scope(state: \.root, action: \.child.root))
			}
		}

		private func root(
			for store: StoreOf<FullScreenOverlayCoordinator.Root>
		) -> some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .claimWallet:
					CaseLet(
						/FullScreenOverlayCoordinator.Root.State.claimWallet,
						action: FullScreenOverlayCoordinator.Root.Action.claimWallet,
						then: { ClaimWallet.View(store: $0) }
					)
				case .relinkConnector:
					CaseLet(
						/FullScreenOverlayCoordinator.Root.State.relinkConnector,
						action: FullScreenOverlayCoordinator.Root.Action.relinkConnector,
						then: { NewConnection.View(store: $0) }
					)
				}
			}
		}
	}
}
