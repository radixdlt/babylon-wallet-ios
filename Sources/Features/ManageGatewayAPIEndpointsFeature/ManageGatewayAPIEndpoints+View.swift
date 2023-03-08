import CreateEntityFeature
import FeaturePrelude

// MARK: - ManageGatewayAPIEndpoints.View
extension ManageGatewayAPIEndpoints {
	public struct ViewState: Equatable {
		public struct GatewayInfo: Equatable {
			let id: String
			let url: String
			let name: String
		}

		public let urlString: String
		public let gatewayInfo: GatewayInfo?
		public let controlState: ControlState
		@BindingState public var focusedField: ManageGatewayAPIEndpoints.State.Field?

		init(state: ManageGatewayAPIEndpoints.State) {
			if let gateway = state.currentGateway {
				gatewayInfo = .init(
					id: String(gateway.network.id),
					url: gateway.url.absoluteString,
					name: [.nebunet: "betanet", .mardunet: "betanet"][gateway.network] ?? gateway.network.name.rawValue
				)
			} else {
				gatewayInfo = nil
			}
			urlString = state.urlString
			controlState = state.controlState
			focusedField = state.focusedField
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ManageGatewayAPIEndpoints>
		@FocusState private var focusedField: ManageGatewayAPIEndpoints.State.Field?

		public init(store: StoreOf<ManageGatewayAPIEndpoints>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: ViewState.init(state:),
				send: { .view($0) }
			) { viewStore in
				core(viewStore: viewStore)
					.sheet(
						store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
						state: /ManageGatewayAPIEndpoints.Destinations.State.createAccount,
						action: ManageGatewayAPIEndpoints.Destinations.Action.createAccount,
						content: { CreateAccountCoordinator.View(store: $0) }
					)
			}
		}
	}
}

extension ManageGatewayAPIEndpoints.View {
	@ViewBuilder
	private func core(viewStore: ViewStoreOf<ManageGatewayAPIEndpoints>) -> some View {
		ScrollView {
			Text(L10n.ManageP2PClients.p2PConnectionsSubtitle)
				.foregroundColor(.app.gray2)
				.textStyle(.body1HighImportance)
				.flushedLeft
				.padding(.medium3)

			Separator()

			VStack(alignment: .leading) {
				if let gatewayInfo = viewStore.gatewayInfo {
					networkAndGatewayView(gatewayInfo)
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
				viewStore.send(.appeared)
			}
		}
	}

	@ViewBuilder
	private func label(
		_ label: String,
		value: String,
		valueColor: Color = Color.app.gray2
	) -> some View {
		VStack(alignment: .leading, spacing: 0) {
			Text(label)
				.foregroundColor(.app.gray1)
				.textStyle(.body1HighImportance)

			Text(value)
				.textSelection(.enabled)
				.foregroundColor(.app.gray2)
				.textStyle(.body2Regular)
		}
		.padding(.top, .small3)
	}

	fileprivate func networkAndGatewayView(
		_ gatewayInfo: ManageGatewayAPIEndpoints.ViewState.GatewayInfo
	) -> some View {
		Group {
			Text(L10n.ManageGateway.currentGatewayTitle)
				.foregroundColor(.app.gray1)
				.textStyle(.secondaryHeader)

			HStack {
				label(L10n.ManageGateway.networkName, value: gatewayInfo.name)
				Spacer()
				label(L10n.ManageGateway.networkID, value: gatewayInfo.id)
			}

			label(
				L10n.ManageGateway.gatewayAPIEndpoint,
				value: gatewayInfo.url, valueColor: .app.blue2
			)
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

extension ManageGatewayAPIEndpoints.State {
	public static let previewValue: Self = .init()
}
#endif
