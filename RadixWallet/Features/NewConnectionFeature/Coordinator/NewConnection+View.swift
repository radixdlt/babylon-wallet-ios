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
					SwitchStore(store) { state in
						switch state {
						case .localNetworkPermission:
							CaseLet(
								/NewConnection.State.localNetworkPermission,
								action: { NewConnection.Action.child(.localNetworkPermission($0)) },
								then: {
									LocalNetworkPermission.View(store: $0)
										.withTitle(L10n.LinkedConnectors.NewConnection.title)
								}
							)
						case .scanQR:
							CaseLet(
								/NewConnection.State.scanQR,
								action: { NewConnection.Action.child(.scanQR($0)) },
								then: {
									ScanQRCoordinator.View(store: $0)
										.withTitle(L10n.LinkedConnectors.NewConnection.title)
								}
							)
						case .connectUsingSecrets:
							CaseLet(
								/NewConnection.State.connectUsingSecrets,
								action: { NewConnection.Action.child(.connectUsingSecrets($0)) },
								then: { ConnectUsingSecrets.View(store: $0) }
							)
						}
					}
				}
				.safeToolbar {
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
