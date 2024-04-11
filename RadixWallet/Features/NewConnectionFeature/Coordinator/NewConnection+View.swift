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

#if DEBUG
import ComposableArchitecture
import SwiftUI

struct NewConnection_Preview: PreviewProvider {
	static var previews: some View {
		NewConnection.View(
			store: .init(
				initialState: .previewValue,
				reducer: NewConnection.init
			)
		)
	}
}

extension NewConnection.State {
	public static let previewValue: Self = .init()
}
#endif
