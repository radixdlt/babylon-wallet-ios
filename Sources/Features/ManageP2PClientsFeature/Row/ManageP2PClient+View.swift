import FeaturePrelude

// MARK: - ManageP2PClient.View
extension ManageP2PClient {
	@MainActor
	public struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.StoreOf<ManageP2PClient>
		public let store: Store
		public init(store: Store) {
			self.store = store
		}
	}
}

extension ManageP2PClient.View {
	public var body: some View {
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

// MARK: - ManageP2PClient.View.ViewState
extension ManageP2PClient.View {
	public struct ViewState: Equatable {
		public var connectionName: String

		init(state: ManageP2PClient.State) {
			connectionName = state.client.displayName
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
