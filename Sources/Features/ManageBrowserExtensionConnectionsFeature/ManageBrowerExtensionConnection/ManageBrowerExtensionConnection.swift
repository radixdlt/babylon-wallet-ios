import BrowserExtensionsConnectivityClient
import ComposableArchitecture
import Converse
import ConverseCommon
import DesignSystem
import Foundation
import SwiftUI

// MARK: - ManageBrowserExtensionConnection
public struct ManageBrowserExtensionConnection: ReducerProtocol {
	@Dependency(\.browserExtensionsConnectivityClient) var browserExtensionsConnectivityClient
	public init() {}
}

public extension ManageBrowserExtensionConnection {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.viewAppeared)):
			return .run { send in
				await send(.internal(.system(.subscribeToConnectionUpdates)))
			}
		case .internal(.system(.subscribeToConnectionUpdates)):
			return .run { [id = state.id] send in
				await withThrowingTaskGroup(of: Void.self) { taskGroup in
					taskGroup.addTask {
						do {
							let statusUpdates = try await browserExtensionsConnectivityClient.getConnectionStatusAsyncSequence(id)
							for try await status in statusUpdates {
								assert(status.browserExtensionConnection.id == id)
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
			print("Failed to get browser connection status update, error \(String(describing: error))")
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

// MARK: ManageBrowserExtensionConnection.State
public extension ManageBrowserExtensionConnection {
	typealias State = BrowserExtensionWithConnectionStatus
}

// MARK: ManageBrowserExtensionConnection.Action
public extension ManageBrowserExtensionConnection {
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case delegate(DelegateAction)
		case `internal`(InternalAction)
	}
}

// MARK: - ManageBrowserExtensionConnection.View.ViewAction
public extension ManageBrowserExtensionConnection.Action {
	enum ViewAction: Equatable {
		case deleteConnectionButtonTapped
		case sendTestMessageButtonTapped
		case viewAppeared
	}
}

public extension ManageBrowserExtensionConnection.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}

	enum DelegateAction: Equatable {
		case deleteConnection
		case sendTestMessage
	}
}

// MARK: - ManageBrowserExtensionConnection.Action.InternalAction.SystemAction
public extension ManageBrowserExtensionConnection.Action.InternalAction {
	enum SystemAction: Equatable {
		case connectionStatusResult(TaskResult<Connection.State>)
		case subscribeToConnectionUpdates
	}
}

// MARK: - ManageBrowserExtensionConnection.View
public extension ManageBrowserExtensionConnection {
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.StoreOf<ManageBrowserExtensionConnection>
		public let store: Store
		public init(store: Store) {
			self.store = store
		}
	}
}

public extension ManageBrowserExtensionConnection.View {
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

// MARK: - ManageBrowserExtensionConnection.View.ViewState
public extension ManageBrowserExtensionConnection.View {
	struct ViewState: Equatable {
		public var connectionID: String
		public var connectionStatus: Connection.State
		init(state: ManageBrowserExtensionConnection.State) {
			connectionID = [
				state.browserExtensionConnection.id.prefix(4),
				"...",
				state.browserExtensionConnection.id.suffix(8),
			].joined()
			connectionStatus = state.connectionStatus
		}
	}
}

public extension ManageBrowserExtensionConnection.View.ViewState {
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
