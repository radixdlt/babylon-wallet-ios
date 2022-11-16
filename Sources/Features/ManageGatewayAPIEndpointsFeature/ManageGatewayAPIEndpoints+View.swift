import ComposableArchitecture
import DesignSystem
import SwiftUI

// MARK: - ManageGatewayAPIEndpoints.View
public extension ManageGatewayAPIEndpoints {
	struct View: SwiftUI.View {
		private let store: StoreOf<ManageGatewayAPIEndpoints>

		public init(store: StoreOf<ManageGatewayAPIEndpoints>) {
			self.store = store
		}
	}
}

public extension ManageGatewayAPIEndpoints.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			Screen(
				title: "Edit Gateway API URL",
				navBarActionStyle: .close,
				action: { viewStore.send(.dismissButtonTapped) }
			) {
				VStack {
					TextField(
						"Gateway API url",
						text: viewStore.binding(
							get: \.gatewayAPIURLString,
							send: { .gatewayAPIURLChanged($0) }
						)
					)

					Button("Switch To") {
						viewStore.send(.switchToButtonTapped)
					}
					.enabled(viewStore.isSwitchToButtonEnabled)
				}
				.buttonStyle(.primary)
			}
		}
	}
}

// MARK: - ManageGatewayAPIEndpoints.View.ViewState
extension ManageGatewayAPIEndpoints.View {
	struct ViewState: Equatable {
		public var gatewayAPIURLString: String
		public var isSwitchToButtonEnabled: Bool
		init(state: ManageGatewayAPIEndpoints.State) {
			gatewayAPIURLString = state.gatewayAPIURLString
			isSwitchToButtonEnabled = state.isSwitchToButtonEnabled
		}
	}
}

// MARK: - ManageGatewayAPIEndpoints_Preview
struct ManageGatewayAPIEndpoints_Preview: PreviewProvider {
	static var previews: some View {
		ManageGatewayAPIEndpoints.View(
			store: .init(
				initialState: .placeholder,
				reducer: ManageGatewayAPIEndpoints()
			)
		)
	}
}
