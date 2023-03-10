import FeaturePrelude

// MARK: - ManageP2PClient.View
extension ManageP2PClient {
	public struct ViewState: Equatable {
		public let connectionName: String

		init(state: ManageP2PClient.State) {
			connectionName = state.client.displayName
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ManageP2PClient>

		public init(store: StoreOf<ManageP2PClient>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: ViewState.init(state:),
				send: { .view($0) }
			) { viewStore in
				VStack(alignment: .leading, spacing: 2) {
					HStack {
						VStack(alignment: .leading) {
							Text(viewStore.connectionName)
								.foregroundColor(.app.gray1)
								.textStyle(.body1HighImportance)
						}

						Spacer()

						Button(
							action: {
								viewStore.send(.deleteConnectionButtonTapped)
							},
							label: {
								Image(asset: AssetResource.delete)
									.foregroundColor(.app.gray1)
							}
						)
					}
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ManageP2PClient_Preview: PreviewProvider {
	static var previews: some View {
		ManageP2PClient.View(
			store: .init(
				initialState: .init(client:
					.init(connectionPassword: .placeholder, displayName: "Test")
				),
				reducer: ManageP2PClient()
			)
		)
	}
}
#endif
