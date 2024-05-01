import ComposableArchitecture
import SwiftUI

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
			screenState = state.isConnecting ? .loading(.global(text: L10n.LinkedConnectors.NewConnection.linking)) : .enabled
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
			WithViewStore(store, observe: ViewState.init(state:), send: { .view($0) }) { viewStore in
				ScrollView(showsIndicators: false) {
					VStack(spacing: 0) {
						Text(L10n.LinkedConnectors.NameNewConnector.title)
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)
							.padding(.bottom, .small1)

						Text(L10n.LinkedConnectors.NameNewConnector.subtitle)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
							.padding(.horizontal, .large1)
							.padding(.bottom, .huge2)

						AppTextField(
							placeholder: "",
							text: viewStore.binding(
								get: \.nameOfConnection,
								send: { .nameOfConnectionChanged($0) }
							),
							hint: .info(L10n.LinkedConnectors.NameNewConnector.textFieldHint),
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
						.padding(.horizontal, .medium3)
					}
				}
				.footer {
					Button(L10n.LinkedConnectors.NameNewConnector.saveLinkButtonTitle) {
						viewStore.send(.confirmNameButtonTapped)
					}
					.controlState(viewStore.saveButtonControlState)
					.buttonStyle(.primaryRectangular)
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
import ComposableArchitecture
import SwiftUI

struct ConnectUsingPassword_Preview: PreviewProvider {
	static var previews: some View {
		ConnectUsingSecrets.View(
			store: .init(
				initialState: .sample,
				reducer: ConnectUsingSecrets.init
			)
		)
	}
}

extension ConnectUsingSecrets.State {
	public static let sample: Self = .init(connectionPassword: .sample)
}

extension RadixConnectPassword {
	public static let sample: Self = .init(value: .sample)
}
#endif
