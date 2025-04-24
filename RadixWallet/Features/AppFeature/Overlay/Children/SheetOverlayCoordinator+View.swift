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

				case .derivePublicKeys:
					CaseLet(
						/SheetOverlayCoordinator.Root.State.derivePublicKeys,
						action: SheetOverlayCoordinator.Root.Action.derivePublicKeys,
						then: { DerivePublicKeys.View(store: $0) }
					)

				case .authorization:
					CaseLet(
						/SheetOverlayCoordinator.Root.State.authorization,
						action: SheetOverlayCoordinator.Root.Action.authorization,
						then: { Authorization.View(store: $0) }
					)

				case .spotCheck:
					CaseLet(
						/SheetOverlayCoordinator.Root.State.spotCheck,
						action: SheetOverlayCoordinator.Root.Action.spotCheck,
						then: { SpotCheck.View(store: $0) }
					)
				}
			}
		}
	}
}
