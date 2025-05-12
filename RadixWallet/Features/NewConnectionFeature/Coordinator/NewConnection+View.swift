import ComposableArchitecture
import SwiftUI

// MARK: - NewConnection.View
extension NewConnection {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<NewConnection>

		init(store: StoreOf<NewConnection>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			NavigationStack {
				ZStack {
					Color.primaryBackground
					root(for: store.scope(state: \.root, action: { .child(.root($0)) }))
				}
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						CloseButton {
							store.send(.view(.closeButtonTapped))
						}
					}
				}
				.background(.primaryBackground)
				.destination(with: store)
			}
			.tint(.primaryText)
			.foregroundColor(.primaryText)
		}

		private func root(
			for store: StoreOf<NewConnection.Root>
		) -> some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .localNetworkPermission:
					CaseLet(
						/NewConnection.Root.State.localNetworkPermission,
						action: NewConnection.Root.Action.localNetworkPermission,
						then: {
							LocalNetworkPermission.View(store: $0)
								// .withTitle(L10n.LinkedConnectors.NewConnection.title)
								.background(.primaryBackground)
						}
					)
				case .scanQR:
					CaseLet(
						/NewConnection.Root.State.scanQR,
						action: NewConnection.Root.Action.scanQR,
						then: {
							ScanQRCoordinator.View(store: $0)
								// .withTitle(L10n.LinkedConnectors.NewConnection.title)
								.background(.primaryBackground)
						}
					)
				case .connectionApproval:
					CaseLet(
						/NewConnection.Root.State.connectionApproval,
						action: NewConnection.Root.Action.connectionApproval,
						then: { NewConnectionApproval.View(store: $0) }
					)
				case .nameConnection:
					CaseLet(
						/NewConnection.Root.State.nameConnection,
						action: NewConnection.Root.Action.nameConnection,
						then: { NewConnectionName.View(store: $0) }
					)
				}
			}
		}
	}
}

extension View {
	func withTitle(_ title: String) -> some View {
		VStack(spacing: .zero) {
			Text(title)
				.foregroundColor(.primaryText)
				.textStyle(.sheetTitle)
				.padding(.bottom, .medium3)

			self

			Spacer(minLength: 0)
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
