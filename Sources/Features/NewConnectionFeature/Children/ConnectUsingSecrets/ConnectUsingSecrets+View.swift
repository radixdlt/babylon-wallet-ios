import FeaturePrelude

// MARK: - ConnectUsingSecrets.State.Field
extension ConnectUsingSecrets.State {
	public enum Field: String, Sendable, Hashable {
		case connectionName
	}
}

// MARK: - ConnectUsingSecrets.View
extension ConnectUsingSecrets {
	public struct ViewState: Equatable {
		public var screenState: ControlState
		public var isPromptingForName: Bool
		public var nameOfConnection: String
		public var isSaveConnectionButtonEnabled: Bool
		@BindableState public var focusedField: ConnectUsingSecrets.State.Field?

		init(state: ConnectUsingSecrets.State) {
			nameOfConnection = state.nameOfConnection
			isPromptingForName = state.isPromptingForName
			screenState = state.isConnecting ? .loading(.global(text: L10n.NewConnection.connecting)) : .enabled
			focusedField = state.focusedField
			isSaveConnectionButtonEnabled = state.isNameValid
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ConnectUsingSecrets>

		@FocusState private var focusedField: ConnectUsingSecrets.State.Field?
		public init(store: StoreOf<ConnectUsingSecrets>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: ViewState.init(state:),
				send: { .view($0) }
			) { viewStore in
				VStack(alignment: .leading) {
					if viewStore.isPromptingForName {
						AppTextField(
							placeholder: L10n.NewConnection.textFieldPlaceholder,
							text: viewStore.binding(
								get: \.nameOfConnection,
								send: { .nameOfConnectionChanged($0) }
							),
							hint: L10n.NewConnection.textFieldHint,
							binding: $focusedField,
							equals: .connectionName,
							first: viewStore.binding(
								get: \.focusedField,
								send: { .textFieldFocused($0) }
							)
						)
						.autocorrectionDisabled()
						.padding(.medium3)

						Spacer()

						Button(L10n.NewConnection.saveNamedConnectionButton) {
							viewStore.send(.confirmNameButtonTapped)
						}
						.controlState(viewStore.isSaveConnectionButtonEnabled ? .enabled : .disabled)
						.buttonStyle(.primaryRectangular)
						.padding(.medium3)
					}
				}
				.controlState(viewStore.screenState)
				.onAppear {
					viewStore.send(.appeared)
				}
				.task { @MainActor in
					await ViewStore(store.stateless).send(.view(.task)).finish()
				}
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
// struct ConnectUsingPassword_Preview: PreviewProvider {
//	static var previews: some View {
//		ConnectUsingSecrets.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: ConnectUsingSecrets()
//			)
//		)
//	}
// }
//
// extension ConnectUsingSecrets.State {
//	public static let previewValue: Self = .init(connectionSecrets: .placeholder)
// }
// #endif
