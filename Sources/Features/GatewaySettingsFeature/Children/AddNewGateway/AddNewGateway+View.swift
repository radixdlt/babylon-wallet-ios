import FeaturePrelude

extension AddNewGateway.State {
	var viewState: AddNewGateway.ViewState {
		.init(
			gatewayURL: inputtedURL,
			focusedField: focusedField,
			fieldHint: errorText.map(AppTextFieldHint.error),
			addGatewayButtonState: addGatewayButtonState
		)
	}
}

// MARK: - AddNewGateway.View
extension AddNewGateway {
	public struct ViewState: Equatable {
		let gatewayURL: String
		let textFieldPlaceholder: String = L10n.GatewaySettings.AddNewGateway.textFieldPlaceholder
		let focusedField: State.Field?
		let fieldHint: AppTextFieldHint?
		let addGatewayButtonState: ControlState
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AddNewGateway>
		@FocusState private var focusedField: State.Field?

		public init(store: StoreOf<AddNewGateway>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						Text(L10n.GatewaySettings.AddNewGateway.title)
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)
							.multilineTextAlignment(.center)

						Text(L10n.GatewaySettings.AddNewGateway.subtitle)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)

						let gatewayURLBinding = viewStore.binding(
							get: \.gatewayURL,
							send: { .textFieldChanged($0) }
						)

						AppTextField(
							placeholder: viewStore.textFieldPlaceholder,
							text: gatewayURLBinding,
							hint: viewStore.fieldHint,
							focus: .on(
								.gatewayURL,
								binding: viewStore.binding(
									get: \.focusedField,
									send: { .textFieldFocused($0) }
								),
								to: $focusedField
							)
						)
						.autocorrectionDisabled()
						#if os(iOS)
							.textInputAutocapitalization(.never)
							.keyboardType(.URL)
						#endif // iOS

						Spacer()

						Button(L10n.GatewaySettings.AddNewGateway.addGatewayButtonTitle) {
							viewStore.send(.addNewGatewayButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
						.controlState(viewStore.addGatewayButtonState)

						Spacer()
					}
					.padding(.horizontal, .medium3)
					.safeAreaInset(edge: .top, alignment: .leading, spacing: .zero) {
						CloseButton { viewStore.send(.closeButtonTapped) }
							.padding([.top, .leading], .small2)
					}
					.onAppear { viewStore.send(.appeared) }
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - AddNewGateway_Preview
struct AddNewGateway_Preview: PreviewProvider {
	static var previews: some View {
		AddNewGateway.View(
			store: .init(
				initialState: .previewValue,
				reducer: AddNewGateway()
			)
		)
	}
}

extension AddNewGateway.State {
	public static let previewValue = Self()
}
#endif
