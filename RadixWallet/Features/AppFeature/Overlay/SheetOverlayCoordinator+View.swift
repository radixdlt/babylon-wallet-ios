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
				case .factorSourceAccess:
					CaseLet(
						/SheetOverlayCoordinator.Root.State.factorSourceAccess,
						action: SheetOverlayCoordinator.Root.Action.factorSourceAccess,
						then: { FactorSourceAccess.View(store: $0) }
					)
				}
			}
		}
	}
}
