import ComposableArchitecture
import Converse
import ConverseCommon
import DesignSystem
import Resources
import SharedModels
import SwiftUI

// MARK: - ManageP2PClient.View
public extension ManageP2PClient {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.StoreOf<ManageP2PClient>
		public let store: Store
		public init(store: Store) {
			self.store = store
		}
	}
}

public extension ManageP2PClient.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			HStack {
				VStack(alignment: .leading) {
					Text(viewStore.connectionName)
						.foregroundColor(.app.gray1)
						.textStyle(.body1HighImportance)

					#if DEBUG
					Text(L10n.ManageP2PClients.connectionID(viewStore.connectionID))
						.foregroundColor(.app.gray1)
						.textStyle(.body1Regular)

					HStack {
						Text(viewStore.connectionStatusDescription)
							.foregroundColor(.app.gray1)
							.textStyle(.body2Regular)

						Circle()
							.fill(viewStore.connectionStatusColor)
							.frame(width: 10)
					}

					Button(L10n.ManageP2PClients.sendTestMessageButtonTitle) {
						viewStore.send(.sendTestMessageButtonTapped)
					}
					.buttonStyle(.secondaryRectangular())
					#endif // DEBUG
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
			.onAppear {
				viewStore.send(.viewAppeared)
			}
		}
	}
}

// MARK: - ManageP2PClient.View.ViewState
public extension ManageP2PClient.View {
	struct ViewState: Equatable {
		public var connectionName: String
		public var connectionStatus: Connection.State
		#if DEBUG
		public var connectionID: String
		#endif // DEBUG
		init(state: ManageP2PClient.State) {
			connectionName = state.p2pClient.displayName
			connectionStatus = state.connectionStatus

			#if DEBUG
			connectionID = [
				state.p2pClient.id.prefix(4),
				"...",
				state.p2pClient.id.suffix(6),
			].joined()
			#endif // DEBUG
		}
	}
}

public extension ManageP2PClient.View.ViewState {
	var connectionStatusDescription: String {
		connectionStatus.rawValue.capitalized
	}

	var connectionStatusColor: Color {
		switch connectionStatus {
		case .disconnected:
			return .red
		case .connecting:
			return .yellow
		case .connected:
			return .green
		}
	}
}
