//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-02.
//

import BrowserExtensionsConnectivityClient
import ComposableArchitecture
import Converse
import ConverseCommon
import DesignSystem
import Foundation
import SwiftUI

// MARK: - ManageBrowserExtensionConnection
public struct ManageBrowserExtensionConnection: ReducerProtocol {
	public init() {}
}

public extension ManageBrowserExtensionConnection {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.user(.deleteConnection)):
			return .run { send in
				await send(.delegate(.deleteConnection))
			}
		case .internal(.user(.sendTestMessage)):
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
	//    struct State: Equatable, Identifiable {
	//        public typealias ID = BrowserExtensionConnectionWithState.ID
	//        public var id: ID { connectionWithState.id }
	//        public var connectionWithState: BrowserExtensionConnectionWithState
//
	//        public init(
	//            connectionWithState: BrowserExtensionConnectionWithState
	//        ) {
	//            self.connectionWithState = connectionWithState
	//        }
	//    }
	typealias State = BrowserExtensionConnectionWithState
}

// MARK: ManageBrowserExtensionConnection.Action
public extension ManageBrowserExtensionConnection {
	enum Action: Equatable {
		case delegate(DelegateAction)
		case `internal`(InternalAction)
	}
}

public extension ManageBrowserExtensionConnection.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}

	enum DelegateAction: Equatable {
		case deleteConnection
		case sendTestMessage
	}
}

// MARK: - ManageBrowserExtensionConnection.Action.InternalAction.UserAction
public extension ManageBrowserExtensionConnection.Action.InternalAction {
	enum UserAction: Equatable {
		case deleteConnection
		case sendTestMessage
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
			send: ManageBrowserExtensionConnection.Action.init
		) { viewStore in
			VStack {
				Text("Connection ID: \(viewStore.connectionID)")

				switch viewStore.connectionStatus {
				case .disconnected:
					HStack {
						Text("Disconnected")
						Circle().fill(Color.red).frame(width: 10)
					}
				case .connected:
					HStack {
						Text("Connected")
						Circle().fill(Color.green).frame(width: 10)
					}
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
		}
	}
}

// MARK: - ManageBrowserExtensionConnection.View.ViewAction
public extension ManageBrowserExtensionConnection.View {
	enum ViewAction: Equatable {
		case deleteConnectionButtonTapped
		case sendTestMessageButtonTapped
	}
}

// MARK: - ManageBrowserExtensionConnection.View.ViewState
public extension ManageBrowserExtensionConnection.View {
	struct ViewState: Equatable {
		public var connectionID: String
		public var connectionStatus: Connection.State
		init(state: ManageBrowserExtensionConnection.State) {
			connectionID = [
				state.browserExtensionConnection.id.suffix(4),
				"...",
				state.browserExtensionConnection.id.suffix(8),
			].joined()
			connectionStatus = state.connectionStatus
		}
	}
}

public extension ManageBrowserExtensionConnection.Action {
	init(action: ManageBrowserExtensionConnection.View.ViewAction) {
		switch action {
		case .deleteConnectionButtonTapped:
			self = .internal(.user(.deleteConnection))
		case .sendTestMessageButtonTapped:
			self = .internal(.user(.sendTestMessage))
		}
	}
}
