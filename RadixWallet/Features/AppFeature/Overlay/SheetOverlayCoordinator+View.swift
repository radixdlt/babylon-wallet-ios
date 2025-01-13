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

				case .signing:
					CaseLet(
						/SheetOverlayCoordinator.Root.State.signing,
						action: SheetOverlayCoordinator.Root.Action.signing,
						then: { Signing.View(store: $0) }
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
