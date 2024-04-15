import ComposableArchitecture
import SwiftUI

// MARK: - NewConnection.View
extension NewConnection {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NewConnection>

		public init(store: StoreOf<NewConnection>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStack {
				ZStack {
					SwitchStore(store.scope(state: \.root, action: \.child)) { state in
						switch state {
						case .localNetworkPermission:
							CaseLet(
								/NewConnection.State.Root.localNetworkPermission,
								action: NewConnection.ChildAction.localNetworkPermission,
								then: {
									LocalNetworkPermission.View(store: $0)
										.withTitle(L10n.LinkedConnectors.NewConnection.title)
								}
							)
						case .scanQR:
							CaseLet(
								/NewConnection.State.Root.scanQR,
								action: NewConnection.ChildAction.scanQR,
								then: {
									ScanQRCoordinator.View(store: $0)
										.withTitle(L10n.LinkedConnectors.NewConnection.title)
								}
							)
						case .connectionApproval:
							CaseLet(
								/NewConnection.State.Root.connectionApproval,
								action: NewConnection.ChildAction.connectionApproval,
								then: { NewConnectionApproval.View(store: $0) }
							)
						case .nameConnection:
							CaseLet(
								/NewConnection.State.Root.nameConnection,
								action: NewConnection.ChildAction.nameConnection,
								then: { NewConnectionName.View(store: $0) }
							)
						}
					}
				}
				.toolbar {
					ToolbarItem(placement: .primaryAction) {
						CloseButton {
							store.send(.view(.closeButtonTapped))
						}
					}
				}
				.destination(with: store)
			}
			.tint(.app.gray1)
			.foregroundColor(.app.gray1)
		}
	}
}

extension View {
	func withTitle(_ title: String) -> some View {
		VStack {
			Text(title)
				.foregroundColor(.app.gray1)
				.textStyle(.sheetTitle)

			Spacer(minLength: 0)

			self
		}
	}
}

@MainActor
private extension View {
	func destination(with store: StoreOf<NewConnection>) -> some View {
		let destination = store.destination
		return alert(store: destination.scope(state: \.errorAlert, action: \.errorAlert))
	}
}

extension StoreOf<NewConnection> {
	var destination: PresentationStoreOf<NewConnection.Destination> {
		func scopeState(state: State) -> PresentationState<NewConnection.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}
