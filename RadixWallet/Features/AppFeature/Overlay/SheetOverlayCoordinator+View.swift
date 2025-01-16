import ComposableArchitecture
import SwiftUI

// MARK: - SheetOverlayCoordinator.View
extension SheetOverlayCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<SheetOverlayCoordinator>

		var body: some SwiftUI.View {
			SwitchStore(store.scope(state: \.root, action: \.child.root)) { state in
				switch state {
				case .infoLink:
					CaseLet(
						/SheetOverlayCoordinator.Root.State.infoLink,
						action: SheetOverlayCoordinator.Root.Action.infoLink,
						then: {
							InfoLinkSheet.View(store: $0)
								.withNavigationBar {
									store.send(.view(.closeButtonTapped))
								}
						}
					)

				case .newSigning:
					CaseLet(
						/SheetOverlayCoordinator.Root.State.newSigning,
						action: SheetOverlayCoordinator.Root.Action.newSigning,
						then: { NewSigning.View(store: $0) }
					)
				}
			}
		}
	}
}
