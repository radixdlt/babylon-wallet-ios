import FeaturePrelude
import ScanQRFeature

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
					SwitchStore(store) {
						CaseLet(
							state: /NewConnection.State.localNetworkPermission,
							action: { NewConnection.Action.child(.localNetworkPermission($0)) },
							then: { LocalNetworkPermission.View(store: $0) }
						)
						CaseLet(
							state: /NewConnection.State.scanQR,
							action: { NewConnection.Action.child(.scanQR($0)) },
							then: { newConnectionStore in
								VStack {
									Text(L10n.LinkedConnectors.NewConnection.title)
										.foregroundColor(.app.gray1)
										.textStyle(.sheetTitle)

									Spacer(minLength: 0)

									ScanQRCoordinator.View(store: newConnectionStore)
								}
							}
						)
						CaseLet(
							state: /NewConnection.State.connectUsingSecrets,
							action: { NewConnection.Action.child(.connectUsingSecrets($0)) },
							then: { ConnectUsingSecrets.View(store: $0) }
						)
					}
				}
				#if os(iOS)
				.toolbar {
					ToolbarItem(placement: .primaryAction) {
						CloseButton {
							ViewStore(store.stateless).send(.view(.closeButtonTapped))
						}
					}
				}
				#endif
			}
			.tint(.app.gray1)
			.foregroundColor(.app.gray1)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct NewConnection_Preview: PreviewProvider {
	static var previews: some View {
		NewConnection.View(
			store: .init(
				initialState: .previewValue,
				reducer: NewConnection()
			)
		)
	}
}

extension NewConnection.State {
	public static let previewValue: Self = .init()
}
#endif
