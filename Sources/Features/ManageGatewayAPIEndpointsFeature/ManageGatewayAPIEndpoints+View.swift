import CreateEntityFeature
import FeaturePrelude

// MARK: - ManageGatewayAPIEndpoints.View
extension ManageGatewayAPIEndpoints {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ManageGatewayAPIEndpoints>
		@FocusState private var focusedField: ManageGatewayAPIEndpoints.State.Field?

		public init(store: StoreOf<ManageGatewayAPIEndpoints>) {
			self.store = store
		}
	}
}

extension ManageGatewayAPIEndpoints.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				ZStack {
					core(viewStore: viewStore)

					IfLetStore(
						store.scope(
							state: \.createAccountCoordinator,
							action: { .createAccountCoordinator($0) }
						),
						then: { CreateAccountCoordinator.View(store: $0) }
					)
				}
			}
		}
	}
}

// MARK: - ManageGatewayAPIEndpoints.View.ViewStore
extension ManageGatewayAPIEndpoints.View {
	fileprivate typealias ViewStore = ComposableArchitecture.ViewStore<ViewState, ManageGatewayAPIEndpoints.Action.ViewAction>
}

extension ManageGatewayAPIEndpoints.View {
	@ViewBuilder
	fileprivate func core(viewStore: ViewStore) -> some View {
		ScrollView {
			Text(L10n.ManageP2PClients.p2PConnectionsSubtitle)
				.foregroundColor(.app.gray2)
				.textStyle(.body1HighImportance)
				.flushedLeft
				.padding(.medium3)

			Separator()

			VStack(alignment: .leading) {
				if let networkAndGateway = viewStore.networkAndGateway {
					networkAndGatewayView(networkAndGateway)
				}

				Spacer(minLength: .large1 * 2)

				AppTextField(
					placeholder: L10n.ManageGateway.textFieldPlaceholder,
					text: viewStore.binding(
						get: \.urlString,
						send: { .urlStringChanged($0) }
					),
					hint: L10n.ManageGateway.textFieldHint,
					binding: $focusedField,
					equals: .gatewayURL,
					first: viewStore.binding(
						get: \.focusedField,
						send: { .focusTextField($0) }
					)
				)
				.autocorrectionDisabled()
				#if os(iOS)
					.textInputAutocapitalization(.never)
					.keyboardType(.URL)
				#endif // iOS

				Spacer(minLength: .large1 * 2)

				Button(L10n.ManageGateway.switchToButtonTitle) {
					viewStore.send(.switchToButtonTapped)
				}
				.buttonStyle(.primaryRectangular)
				.controlState(viewStore.controlState)
			}
			.padding(.medium3)
			.navigationTitle(L10n.ManageGateway.title)
			.onAppear {
				viewStore.send(.didAppear)
			}
		}
	}

	@ViewBuilder
	fileprivate func label(
		_ label: String,
		value: CustomStringConvertible,
		valueColor: Color = Color.app.gray2
	) -> some View {
		VStack(alignment: .leading, spacing: 0) {
			Text(label)
				.foregroundColor(.app.gray1)
				.textStyle(.body1HighImportance)

			Text(String(describing: value))
				.textSelection(.enabled)
				.foregroundColor(.app.gray2)
				.textStyle(.body2Regular)
		}
		.padding(.top, .small3)
	}

	fileprivate func networkAndGatewayView(
		_ networkAndGateway: AppPreferences.NetworkAndGateway
	) -> some View {
		Group {
			Text(L10n.ManageGateway.currentGatewayTitle)
				.foregroundColor(.app.gray1)
				.textStyle(.secondaryHeader)

			HStack {
				label(L10n.ManageGateway.networkName, value: ViewState.resolveName(network: networkAndGateway.network))
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
		public var controlState: ControlState
		@BindingState public var focusedField: ManageGatewayAPIEndpoints.State.Field?

		init(state: ManageGatewayAPIEndpoints.State) {
			urlString = state.urlString
			networkAndGateway = state.currentNetworkAndGateway
			controlState = state.controlState
			focusedField = state.focusedField
		}
	}
}

extension ManageGatewayAPIEndpoints.View.ViewState {
	static func resolveName(network: Network) -> String {
		networkNameMap[network] ?? network.name.rawValue
	}

	private static let networkNameMap: [Network: String] = [.nebunet: "betanet", .mardunet: "betanet"]
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ManageGatewayAPIEndpoints_Preview: PreviewProvider {
	static var previews: some View {
		ManageGatewayAPIEndpoints.View(
			store: .init(
				initialState: .previewValue,
				reducer: ManageGatewayAPIEndpoints()
			)
		)
	}
}
#endif
