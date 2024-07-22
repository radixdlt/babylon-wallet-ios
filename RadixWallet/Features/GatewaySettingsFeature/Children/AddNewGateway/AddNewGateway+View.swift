import ComposableArchitecture
import SwiftUI

extension AddNewGateway.State {
	var viewState: AddNewGateway.ViewState {
		.init(
			gatewayURL: inputtedURL,
			focusedField: focusedField,
			fieldHint: errorText.map(Hint.error),
			addGatewayButtonState: addGatewayButtonState
		)
	}
}

// MARK: - AddNewGateway.View
extension AddNewGateway {
	public struct ViewState: Equatable {
		let gatewayURL: String
		let textFieldPlaceholder: String = L10n.Gateways.AddNewGateway.textFieldPlaceholder
		let focusedField: State.Field?
		let fieldHint: Hint?
		let addGatewayButtonState: ControlState
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AddNewGateway>
		@FocusState private var focusedField: State.Field?
		@Environment(\.dismiss) var dismiss

		public init(store: StoreOf<AddNewGateway>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			content
				.withNavigationBar {
					dismiss()
				}
				.presentationDetents([.fraction(0.55)])
				.presentationDragIndicator(.visible)
				.presentationBackground(.blur)
		}

		private var content: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						Text(L10n.Gateways.AddNewGateway.title)
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)
							.multilineTextAlignment(.center)

						Text(L10n.Gateways.AddNewGateway.subtitle)
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
						.padding(.top, .small3)
						.textInputAutocapitalization(.never)
						.keyboardType(.URL)
						.autocorrectionDisabled()
					}
					.padding(.top, .medium3)
					.padding(.bottom, .medium1)
					.padding(.horizontal, .large2)
				}
				.footer {
					Button(L10n.Gateways.AddNewGateway.addGatewayButtonTitle) {
						viewStore.send(.addNewGatewayButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
					.controlState(viewStore.addGatewayButtonState)
				}
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - AddNewGateway_Preview
struct AddNewGateway_Preview: PreviewProvider {
	static var previews: some View {
		AddNewGateway.View(
			store: .init(
				initialState: .previewValue,
				reducer: AddNewGateway.init
			)
		)
	}
}

extension AddNewGateway.State {
	public static let previewValue = Self()
}
#endif
