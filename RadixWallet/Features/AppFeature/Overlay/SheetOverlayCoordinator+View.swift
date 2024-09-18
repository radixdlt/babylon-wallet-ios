import ComposableArchitecture
import SwiftUI

// MARK: - SheetOverlayCoordinator.View
extension SheetOverlayCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SheetOverlayCoordinator>

		public init(store: StoreOf<SheetOverlayCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithNavigationBar {
				store.send(.view(.closeButtonTapped))
			} content: {
				root(for: store.scope(state: \.root, action: \.child.root))
			}
		}

		private func root(
			for store: StoreOf<SheetOverlayCoordinator.Root>
		) -> some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .infoLink:
					CaseLet(
						/SheetOverlayCoordinator.Root.State.infoLink,
						action: SheetOverlayCoordinator.Root.Action.infoLink,
						then: { InfoLinkSheet.View(store: $0) }
					)
				}
			}
		}
	}
}
