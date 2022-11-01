import Common
import ComposableArchitecture
import DesignSystem
import Foundation
import InputPasswordFeature
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
				ZStack {
					manageBrowserExtensionConnectionsView(viewStore: viewStore)
						.zIndex(0)

					IfLetStore(
						store.scope(
							state: \.inputBrowserExtensionConnectionPassword,
							action: ManageBrowserExtensionConnections.Action.inputBrowserExtensionConnectionPassword
						),
						then: { inputPasswordStore in
							Screen(
								title: "New Connection",
								navBarActionStyle: .close,
								action: { viewStore.send(.dismissNewConnectionFlowButtonTapped) }
							) {
								VStack {
									InputPassword.View(store: inputPasswordStore)
								}
								.padding()
							}
						}
					)
					.zIndex(1)
				}
			}
		}
	}
}

private extension ManageBrowserExtensionConnections.View {
	func manageBrowserExtensionConnectionsView(
		viewStore: ViewStore<ViewState, ViewAction>
	) -> some View {
		Screen(
			title: "Browser Connections",
			navBarActionStyle: .back,
			action: { viewStore.send(.dismissButtonTapped) }
		) {
			VStack {
				Spacer()
				Button("Add new connection") { viewStore.send(.addNewConnectionButtonTapped) }
				Spacer()
			}
		}
	}
}

// MARK: - ManageBrowserExtensionConnections.View.ViewAction
public extension ManageBrowserExtensionConnections.View {
	enum ViewAction: Equatable {
		case dismissButtonTapped
		case addNewConnectionButtonTapped
		case dismissNewConnectionFlowButtonTapped
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
		case .addNewConnectionButtonTapped:
			self = .internal(.user(.addNewConnection))
		case .dismissNewConnectionFlowButtonTapped:
			self = .internal(.user(.dismissNewConnectionFlow))
		}
	}
}
