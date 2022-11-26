import ComposableArchitecture
import DesignSystem
import Profile
import SwiftUI
import URLBuilderClient

// MARK: - ManageGatewayAPIEndpoints.View
public extension ManageGatewayAPIEndpoints {
	@MainActor
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
			ForceFullScreen {
				VStack {
					NavigationBar(
						titleText: "Edit Gateway API URL",
						leadingItem: CloseButton {
							viewStore.send(.dismissButtonTapped)
						}
					)
					.foregroundColor(.app.gray1)
					.padding([.horizontal, .top], .medium3)

					VStack(alignment: .leading) {
						if let networkAndGateway = viewStore.networkAndGateway {
							networkAndGatewayView(networkAndGateway)
						}

						Spacer()

						ZStack {
							VStack {
								TextField(
									"Scheme",
									text: viewStore.binding(
										get: \.scheme,
										send: { .schemeChanged($0) }
									)
								)

								TextField(
									"Host",
									text: viewStore.binding(
										get: \.host,
										send: { .hostChanged($0) }
									)
								)

								TextField(
									"Path",
									text: viewStore.binding(
										get: \.path,
										send: { .pathChanged($0) }
									)
								)

								TextField(
									"Port",
									text: viewStore.binding(
										get: \.port,
										send: { .portChanged($0) }
									)
								)
							}
							.textFieldStyle(.roundedBorder)

							if viewStore.isShowingLoader {
								LoadingView()
							}
						}

						Spacer()

						Button("Switch To") {
							viewStore.send(.switchToButtonTapped)
						}
						.enabled(viewStore.isSwitchToButtonEnabled)
					}
					.padding([.horizontal, .bottom], .medium1)
					.buttonStyle(.primaryRectangular)
				}
				.onAppear {
					viewStore.send(.didAppear)
				}
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
		VStack(alignment: .leading) {
			Text(label)
				.foregroundColor(.app.gray2)
				.textStyle(.body2HighImportance)

			Text(String(describing: value))
				.textSelection(.enabled)
				.foregroundColor(.app.gray1)
				.textStyle(.body1HighImportance)
		}
		.padding(.top, .small3)
	}

	func networkAndGatewayView(
		_ networkAndGateway: AppPreferences.NetworkAndGateway
	) -> some View {
		Group {
			Text("Current")
				.foregroundColor(.app.gray1)
				.textStyle(.sectionHeader)

			label("Network name", value: networkAndGateway.network.name)
			label("Network ID", value: networkAndGateway.network.id)
			label("Gateway API Endpoint", value: URLBuilderClient.liveValue.formatURL(networkAndGateway.gatewayAPIEndpointURL), valueColor: .app.blue2)
		}
	}
}

// MARK: - ManageGatewayAPIEndpoints.View.ViewState
extension ManageGatewayAPIEndpoints.View {
	struct ViewState: Equatable {
		public var host: String
		public var path: String
		public var scheme: String
		public var port: String

		public var networkAndGateway: AppPreferences.NetworkAndGateway?
		public var isSwitchToButtonEnabled: Bool
		public var isShowingLoader: Bool

		init(state: ManageGatewayAPIEndpoints.State) {
			host = state.host ?? ""
			scheme = state.scheme
			path = state.path
			port = state.port?.description ?? ""

			isSwitchToButtonEnabled = state.url != nil
			networkAndGateway = state.networkAndGateway
			isShowingLoader = state.isValidatingEndpoint
		}
	}
}

// MARK: - ManageGatewayAPIEndpoints_Preview
#if DEBUG
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
#endif
