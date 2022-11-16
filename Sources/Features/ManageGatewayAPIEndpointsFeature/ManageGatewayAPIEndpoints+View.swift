import ComposableArchitecture
import DesignSystem
import Profile
import SwiftUI
import URLBuilderClient

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
				VStack(alignment: .leading) {
					if let networkAndGateway = viewStore.networkAndGateway {
						networkAndGatewayView(networkAndGateway)
					}

					Spacer()

					Group {
						let prompt = "Gateway API URL"
						Text(prompt)
							.font(.callout)
						TextField(
							prompt,
							text: viewStore.binding(
								get: \.gatewayAPIURLString,
								send: { .gatewayAPIURLChanged($0) }
							)
						)
						.textFieldStyle(.roundedBorder)
					}

					Spacer()

					Button("Switch To") {
						viewStore.send(.switchToButtonTapped)
					}
					.enabled(viewStore.isSwitchToButtonEnabled)
				}
				.padding()
				.buttonStyle(.primary)
			}
			.onAppear {
				viewStore.send(.didAppear)
			}
		}
	}
}

private extension ManageGatewayAPIEndpoints.View {
	@ViewBuilder
	func label(
		_ label: String,
		value: CustomStringConvertible,
		valueColor: Color = Color.app.gray2
	) -> some View {
		Group {
			Text(label)
				.font(.headline)
				.foregroundColor(Color.app.gray1)
			Text(String(describing: value))
				.textSelection(.enabled)
				.font(.title3)
				.foregroundColor(valueColor)
		}
	}

	func networkAndGatewayView(
		_ networkAndGateway: AppPreferences.NetworkAndGateway
	) -> some View {
		Group {
			Text("Current")
				.font(.title2)

			label("Network name", value: networkAndGateway.network.name)
			label("Network ID", value: networkAndGateway.network.id)
			label("Gateway API Endpoint", value: URLBuilderClient.liveValue.formatURL(networkAndGateway.gatewayAPIEndpointURL), valueColor: Color.app.blue2)
		}
	}
}

// MARK: - ManageGatewayAPIEndpoints.View.ViewState
extension ManageGatewayAPIEndpoints.View {
	struct ViewState: Equatable {
		public var gatewayAPIURLString: String
		public var networkAndGateway: AppPreferences.NetworkAndGateway?
		public var isSwitchToButtonEnabled: Bool

		init(state: ManageGatewayAPIEndpoints.State) {
			gatewayAPIURLString = state.gatewayAPIURLString
			isSwitchToButtonEnabled = state.isSwitchToButtonEnabled
			networkAndGateway = state.networkAndGateway
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
