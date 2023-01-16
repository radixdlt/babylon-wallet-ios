import CreateAccountFeature
import FeaturePrelude

// MARK: - ManageGatewayAPIEndpoints.View
public extension ManageGatewayAPIEndpoints {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ManageGatewayAPIEndpoints>
		@FocusState private var focusedField: ManageGatewayAPIEndpoints.State.Field?

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
							state: \.createAccountCoordinator,
							action: { .createAccountCoordinator($0) }
						),
						then: { CreateAccountCoordinator.View(store: $0) }
					)
					.zIndex(1)
				}
			}
		}
	}
}

// MARK: - ManageGatewayAPIEndpoints.View.ViewStore
private extension ManageGatewayAPIEndpoints.View {
	typealias ViewStore = ComposableArchitecture.ViewStore<ViewState, ManageGatewayAPIEndpoints.Action.ViewAction>
}

private extension ManageGatewayAPIEndpoints.View {
	@ViewBuilder
	func core(viewStore: ViewStore) -> some View {
		ForceFullScreen {
			VStack(spacing: .zero) {
				NavigationBar(
					titleText: L10n.ManageGateway.title,
					leadingItem: BackButton {
						viewStore.send(.dismissButtonTapped)
					}
				)
				.foregroundColor(.app.gray1)
				.padding([.horizontal, .top], .medium3)

				Separator()

				ScrollView {
					HStack {
						Text(L10n.ManageP2PClients.p2PConnectionsSubtitle)
							.foregroundColor(.app.gray2)
							.textStyle(.body1HighImportance)
							.padding(.medium3)

						Spacer()
					}

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
				}
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
				.foregroundColor(.app.gray1)
				.textStyle(.body1HighImportance)

			Text(String(describing: value))
				.textSelection(.enabled)
				.foregroundColor(.app.gray2)
				.textStyle(.body2Regular)
		}
		.padding(.top, .small3)
	}

	func networkAndGatewayView(
		_ networkAndGateway: AppPreferences.NetworkAndGateway
	) -> some View {
		Group {
			Text(L10n.ManageGateway.currentGatewayTitle)
				.foregroundColor(.app.gray1)
				.textStyle(.secondaryHeader)

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
		public var controlState: ControlState
		@BindableState public var focusedField: ManageGatewayAPIEndpoints.State.Field?

		init(state: ManageGatewayAPIEndpoints.State) {
			urlString = state.urlString
			networkAndGateway = state.currentNetworkAndGateway
			controlState = state.controlState
			focusedField = state.focusedField
		}
	}
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
