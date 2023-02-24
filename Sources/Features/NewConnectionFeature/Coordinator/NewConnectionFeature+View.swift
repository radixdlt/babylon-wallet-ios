import FeaturePrelude

// MARK: - NewConnection.View
extension NewConnection {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NewConnection>

		public init(store: StoreOf<NewConnection>) {
			self.store = store
		}
	}
}

extension NewConnection.View {
	public var body: some View {
		NavigationStack {
			SwitchStore(store) {
				CaseLet(
					state: /NewConnection.State.localNetworkPermission,
					action: { NewConnection.Action.child(.localNetworkPermission($0)) },
					then: { LocalNetworkPermission.View(store: $0) }
				)
				CaseLet(
					state: /NewConnection.State.cameraPermission,
					action: { NewConnection.Action.child(.cameraPermission($0)) },
					then: { CameraPermission.View(store: $0) }
				)
				CaseLet(
					state: /NewConnection.State.scanQR,
					action: { NewConnection.Action.child(.scanQR($0)) },
					then: { ScanQR.View(store: $0) }
				)
				CaseLet(
					state: /NewConnection.State.connectUsingSecrets,
					action: { NewConnection.Action.child(.connectUsingSecrets($0)) },
					then: { ConnectUsingSecrets.View(store: $0) }
				)
			}
			.navigationTitle(L10n.NewConnection.title)
			#if os(iOS)
				.navigationBarTitleColor(.app.gray1)
				.navigationBarTitleDisplayMode(.inline)
				.navigationBarInlineTitleFont(.app.secondaryHeader)
				.toolbar {
					ToolbarItem(placement: .navigationBarLeading) {
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
#endif
