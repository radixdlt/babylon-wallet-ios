import ComposableArchitecture
import SwiftUI

extension AddNewGateway.State {
	var fieldHint: Hint.ViewState? {
		errorText.map(Hint.ViewState.iconError)
	}
}

// MARK: - AddNewGateway.View
extension AddNewGateway {
	@MainActor
	public struct View: SwiftUI.View {
		@Perception.Bindable private var store: StoreOf<AddNewGateway>
		@FocusState private var focusedField: State.Field?
		@Environment(\.dismiss) var dismiss
		private let detentFraction: CGFloat = 0.55

		public init(store: StoreOf<AddNewGateway>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			content
				.withNavigationBar {
					dismiss()
				}
				.presentationDetents([.fraction(detentFraction)])
				.presentationDragIndicator(.visible)
				.presentationBackground(.blur)
		}

		private var content: some SwiftUI.View {
			WithPerceptionTracking {
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

						AppTextField(
							placeholder: L10n.Gateways.AddNewGateway.textFieldPlaceholder,
							text: $store.inputtedURL.sending(\.view.textFieldChanged),
							hint: store.fieldHint,
							focus: .on(
								.gatewayURL,
								binding: $store.focusedField.sending(\.view.textFieldFocused),
								to: $focusedField
							)
						)
						.padding(.top, .small3)
						.textInputAutocapitalization(.never)
						.keyboardType(.URL)
						.autocorrectionDisabled()
					}
					.padding(.top, .medium3)
					.padding(.horizontal, .large2)
					.padding(.bottom, .medium1)
				}
				.footer {
					Button(L10n.Gateways.AddNewGateway.addGatewayButtonTitle) {
						store.send(.view(.addNewGatewayButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
					.controlState(store.addGatewayButtonState)
				}
				.onAppear { store.send(.view(.appeared)) }
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
