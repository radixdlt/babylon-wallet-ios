import ComposableArchitecture
import SwiftUI

// MARK: - NewConnectionName.State.Field
extension NewConnectionName.State {
	enum Field: String, Sendable, Hashable {
		case connectionName
	}
}

// MARK: - NewConnectionName.View
extension NewConnectionName {
	struct ViewState: Equatable {
		let screenState: ControlState
		let nameOfConnection: String
		let saveButtonControlState: ControlState
		let focusedField: NewConnectionName.State.Field?

		init(state: NewConnectionName.State) {
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
	struct View: SwiftUI.View {
		private let store: StoreOf<NewConnectionName>

		@FocusState private var focusedField: NewConnectionName.State.Field?
		init(store: StoreOf<NewConnectionName>) {
			self.store = store
		}

		var body: some SwiftUI.View {
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

struct NewConnectionName_Preview: PreviewProvider {
	static var previews: some View {
		NewConnectionName.View(
			store: .init(
				initialState: .sample,
				reducer: NewConnectionName.init
			)
		)
	}
}

extension NewConnectionName.State {
	static let sample: Self = .init()
}
#endif
