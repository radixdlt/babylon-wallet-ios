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
				SwitchStore(store) {
					CaseLet(
						state: /NewConnection.State.localNetworkPermission,
						action: { NewConnection.Action.child(.localNetworkPermission($0)) },
						then: { LocalNetworkPermission.View(store: $0) }
					)
					CaseLet(
						state: /NewConnection.State.scanQR,
						action: { NewConnection.Action.child(.scanQR($0)) },
						then: { ScannQR.View(store: $0) }
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
