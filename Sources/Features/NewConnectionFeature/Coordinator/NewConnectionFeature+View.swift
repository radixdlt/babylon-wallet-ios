import ComposableArchitecture
import DesignSystem
import Resources
import SwiftUI

// MARK: - NewConnection.View
public extension NewConnection {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<NewConnection>

		public init(store: StoreOf<NewConnection>) {
			self.store = store
		}
	}
}

public extension NewConnection.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				VStack {
					NavigationBar(
						titleText: L10n.NewConnection.title,
						leadingItem: BackButton {
							viewStore.send(.dismissButtonTapped)
						}
					)
					.foregroundColor(.app.gray1)
					.padding([.horizontal, .top], .medium3)

					Spacer()
					ForceFullScreen {
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
					}
				}
			}
		}
	}
}

// MARK: - NewConnection.View.ViewState
public extension NewConnection.View {
	struct ViewState: Equatable {
		init(state: NewConnection.State) {}
	}
}

#if DEBUG

// MARK: - NewConnection_Preview
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
