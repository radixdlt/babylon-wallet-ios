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
		let screenState: ControlState
		let nameOfConnection: String
		let saveButtonControlState: ControlState
		let focusedField: ConnectUsingSecrets.State.Field?

		init(state: ConnectUsingSecrets.State) {
			nameOfConnection = state.nameOfConnection
			screenState = state.isConnecting ? .loading(.global(text: L10n.NewConnection.linking)) : .enabled
			focusedField = state.focusedField
			saveButtonControlState = {
				if state.isConnecting {
					return .loading(.local)
				}
				return state.isNameValid ? .enabled : .disabled
			}()
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
					AppTextField(
						placeholder: L10n.NewConnection.textFieldPlaceholder,
						text: viewStore.binding(
							get: \.nameOfConnection,
							send: { .nameOfConnectionChanged($0) }
						),
						hint: .info(L10n.NewConnection.textFieldHint),
						focus: .on(
							.connectionName,
							binding: viewStore.binding(
								get: \.focusedField,
								send: { .textFieldFocused($0) }
							),
							to: $focusedField
						)
					)
					.autocorrectionDisabled()
					.padding(.medium3)

					Spacer()

					Button(L10n.NewConnection.saveLinkButtonTitle) {
						viewStore.send(.confirmNameButtonTapped)
					}
					.controlState(viewStore.saveButtonControlState)
					.buttonStyle(.primaryRectangular)
					.padding(.medium3)
				}
				.controlState(viewStore.screenState)
				.onAppear {
					viewStore.send(.appeared)
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ConnectUsingPassword_Preview: PreviewProvider {
	static var previews: some View {
		ConnectUsingSecrets.View(
			store: .init(
				initialState: .previewValue,
				reducer: ConnectUsingSecrets()
			)
		)
	}
}

extension ConnectUsingSecrets.State {
	public static let previewValue: Self = .init(connectionPassword: .placeholder)
}
#endif
