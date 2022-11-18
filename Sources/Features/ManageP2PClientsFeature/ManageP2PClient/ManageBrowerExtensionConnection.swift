import ComposableArchitecture
import Converse
import ConverseCommon
import DesignSystem
import ErrorQueue
import Foundation
import P2PConnectivityClient
import SharedModels
import SwiftUI

// MARK: - ManageP2PClient
public struct ManageP2PClient: ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pConnectivityClient) var p2pConnectivityClient
	public init() {}
}

public extension ManageP2PClient {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.viewAppeared)):
			return .run { [id = state.id] send in
				await withThrowingTaskGroup(of: Void.self) { taskGroup in
					taskGroup.addTask {
						do {
							let statusUpdates = try await p2pConnectivityClient.getConnectionStatusAsyncSequence(id)
							for try await status in statusUpdates {
								assert(status.p2pClient.id == id)
								await send(.internal(.system(.connectionStatusResult(
									TaskResult.success(status.connectionStatus)
								))))
							}
						} catch {
							await send(.internal(.system(.connectionStatusResult(
								TaskResult.failure(error)
							))))
						}
					}
				}
			}

		case let .internal(.system(.connectionStatusResult(.success(newStatus)))):
			state.connectionStatus = newStatus
			return .none

		case let .internal(.system(.connectionStatusResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .internal(.view(.deleteConnectionButtonTapped)):
			return .run { send in
				await send(.delegate(.deleteConnection))
			}
		case .internal(.view(.sendTestMessageButtonTapped)):
			return .run { send in
				await send(.delegate(.sendTestMessage))
			}
		case .delegate:
			return .none
		}
	}
}

// MARK: ManageP2PClient.State
public extension ManageP2PClient {
	typealias State = P2P.ClientWithConnectionStatus
}

// MARK: ManageP2PClient.Action
public extension ManageP2PClient {
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case delegate(DelegateAction)
		case `internal`(InternalAction)
	}
}

// MARK: - ManageP2PClient.Action.ViewAction
public extension ManageP2PClient.Action {
	enum ViewAction: Equatable {
		case deleteConnectionButtonTapped
		case sendTestMessageButtonTapped
		case viewAppeared
	}
}

public extension ManageP2PClient.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}

	enum DelegateAction: Equatable {
		case deleteConnection
		case sendTestMessage
	}
}

// MARK: - ManageP2PClient.Action.InternalAction.SystemAction
public extension ManageP2PClient.Action.InternalAction {
	enum SystemAction: Equatable {
		case connectionStatusResult(TaskResult<Connection.State>)
	}
}

// MARK: - ManageP2PClient.View
public extension ManageP2PClient {
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
			VStack {
				Text("Connection ID: \(viewStore.connectionID)")
				HStack {
					Text(viewStore.connectionStatusDescription)
					Circle().fill(viewStore.connectionStatusColor).frame(width: 10)
				}

				HStack {
					Button("Delete", role: .destructive) {
						viewStore.send(.deleteConnectionButtonTapped)
					}

					Button("Send Test Msg") {
						viewStore.send(.sendTestMessageButtonTapped)
					}
				}
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
		public var connectionID: String
		public var connectionStatus: Connection.State
		init(state: ManageP2PClient.State) {
			connectionID = [
				state.p2pClient.id.prefix(4),
				"...",
				state.p2pClient.id.suffix(8),
			].joined()
			connectionStatus = state.connectionStatus
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
