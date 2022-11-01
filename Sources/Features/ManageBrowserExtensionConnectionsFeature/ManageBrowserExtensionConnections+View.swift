import Common
import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - ManageBrowserExtensionConnections.View
public extension ManageBrowserExtensionConnections {
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.StoreOf<ManageBrowserExtensionConnections>
		public let store: Store
		public init(store: Store) {
			self.store = store
		}
	}
}

public extension ManageBrowserExtensionConnections.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: ManageBrowserExtensionConnections.Action.init
		) { viewStore in
			ForceFullScreen {
				VStack {
					HStack {
						Button(
							action: {
								viewStore.send(.dismissButtonTapped)
							}, label: {
								Image("arrow-back")
							}
						)
						Spacer()
						Text("Manage Browser Connections")
						Spacer()
						EmptyView()
					}
					Spacer()
					Text("ManageBrowserExtensionConnections")
				}
			}
		}
	}
}

// MARK: - ManageBrowserExtensionConnections.View.ViewAction
public extension ManageBrowserExtensionConnections.View {
	enum ViewAction: Equatable {
		case dismissButtonTapped
	}
}

// MARK: - ManageBrowserExtensionConnections.View.ViewState
public extension ManageBrowserExtensionConnections.View {
	struct ViewState: Equatable {
		init(state _: ManageBrowserExtensionConnections.State) {}
	}
}

extension ManageBrowserExtensionConnections.Action {
	init(action: ManageBrowserExtensionConnections.View.ViewAction) {
		switch action {
		case .dismissButtonTapped:
			self = .internal(.user(.dismiss))
		}
	}
}
