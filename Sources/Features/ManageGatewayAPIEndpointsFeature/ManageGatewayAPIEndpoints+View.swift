import Common
import ComposableArchitecture
import CreateAccountFeature
import DesignSystem
import Profile
import SwiftUI

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
				ZStack {
					core(viewStore: viewStore)
						.zIndex(0)

					IfLetStore(
						store.scope(
							state: \.createAccount,
							action: { .createAccount($0) }
						),
						then: CreateAccount.View.init(store:)
					)
					.zIndex(1)
				}
			}
		}
	}
}

private extension ManageGatewayAPIEndpoints.View {
	@ViewBuilder
	func core(viewStore: ViewStore<ViewState, ManageGatewayAPIEndpoints.Action.ViewAction>) -> some View {
		ForceFullScreen {
			VStack {
				NavigationBar(
					titleText: L10n.ManageGateway.title,
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
						VStack(alignment: .leading) {
							Text(L10n.ManageGateway.inputNewGatewayAPIURL)
							TextField(
								L10n.ManageGateway.urlString,
								text: viewStore.binding(
									get: \.urlString,
									send: { .urlStringChanged($0) }
								)
							)
							.textFieldStyle(.roundedBorder)
						}

						// FIXME: betanet move loading indicator into button below.
						if viewStore.isShowingLoader {
							LoadingView()
						}
					}

					Spacer()

					Button(L10n.ManageGateway.switchToButtonTitle) {
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

	@ViewBuilder
	func label(
		_ label: String,
		value: CustomStringConvertible,
		valueColor: Color = Color.app.gray2
	) -> some View {
		VStack(alignment: .leading, spacing: 0) {
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
			Text(L10n.ManageGateway.currentGatewayTitle)
				.foregroundColor(.app.gray1)
				.textStyle(.sectionHeader)

			HStack {
				label(L10n.ManageGateway.networkName, value: networkAndGateway.network.name)
				Spacer()
				label(L10n.ManageGateway.networkID, value: networkAndGateway.network.id)
			}

			label(
				L10n.ManageGateway.gatewayAPIEndpoint,
				value: networkAndGateway.gatewayAPIEndpointURL.absoluteString, valueColor: .app.blue2
			)
		}
	}
}

// MARK: - ManageGatewayAPIEndpoints.View.ViewState
extension ManageGatewayAPIEndpoints.View {
	struct ViewState: Equatable {
		public var urlString: String

		public var networkAndGateway: AppPreferences.NetworkAndGateway?
		public var isSwitchToButtonEnabled: Bool
		public var isShowingLoader: Bool

		init(state: ManageGatewayAPIEndpoints.State) {
			urlString = state.urlString

			isSwitchToButtonEnabled = state.isSwitchToButtonEnabled
			networkAndGateway = state.currentNetworkAndGateway
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
