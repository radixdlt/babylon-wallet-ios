import EditPersonaFeature
import FeaturePrelude

extension PersonaDataPermissionBox.State {
	var viewState: PersonaDataPermissionBox.ViewState {
		.init(
			personaLabel: persona.displayName.rawValue,
			existingRequiredEntries: responseValidation.existingRequestedEntries
				.sorted(by: \.key)
				.map { $0.value.map(\.description).joined(separator: ", ") }
				.nilIfEmpty?
				.joined(separator: "\n"),

			missingRequiredEntries:
			responseValidation.missingEntries
				.keys
				.nilIfEmpty
				.map { kinds in
					.error {
						Text {
							L10n.DAppRequest.PersonalDataBox.requiredInformation.text.bold()
							" "
							kinds.sorted().map(\.title.localizedLowercase).joined(separator: ", ")
						}
					}
				}
		)
	}
}

extension PersonaDataPermissionBox {
	struct ViewState: Equatable {
		let personaLabel: String
		let existingRequiredEntries: String?
		let missingRequiredEntries: Hint?
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<PersonaDataPermissionBox>
		let action: () -> Void
		let accessory: AnyView

		init(
			store: StoreOf<PersonaDataPermissionBox>,
			action: @escaping () -> Void = {},
			@ViewBuilder accessory: () -> some SwiftUI.View = { EmptyView() }
		) {
			self.store = store
			self.action = action
			self.accessory = AnyView(accessory())
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				DappPermissionBox {
					Button(action: action) {
						HStack(spacing: .medium2) {
							Circle()
								.strokeBorder(Color.app.gray3, lineWidth: 1)
								.background(Circle().fill(Color.app.gray4))
								.frame(.small)
							Text(viewStore.personaLabel)
								.foregroundColor(.app.gray1)
								.textStyle(.secondaryHeader)
							Spacer()
							accessory
						}
						.padding(.medium2)
					}
					.buttonStyle(.inert)
				} content: {
					VStack(alignment: .leading, spacing: .small1) {
						if let existingRequiredFields = viewStore.existingRequiredEntries {
							Text(existingRequiredFields)
								.foregroundColor(.app.gray2)
								.textStyle(.body2Regular)
						}

						viewStore.missingRequiredEntries

						Button(L10n.DAppRequest.PersonalDataBox.edit) {
							viewStore.send(.editButtonTapped)
						}
						.modifier {
							if viewStore.missingRequiredEntries != nil {
								$0.buttonStyle(.primaryRectangular)
							} else {
								$0.buttonStyle(.secondaryRectangular(shouldExpand: true))
							}
						}
					}
					.padding(.medium2)
				}
			}
		}
	}
}

//
// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
// struct PersonaDataPermissionBox_PreviewProvider: PreviewProvider {
//	static var previews: some View {
//		WithState(initialValue: false) { $isSelected in
//			PersonaDataPermissionBox.View(
//				store: Store(
//					initialState: .init(
//						persona: .previewValue0,
//						requiredFieldIDs: [.givenName, .emailAddress]
//					),
//					reducer: PersonaDataPermissionBox.init
//				),
//				action: { isSelected.toggle() }
//			) {
//				RadioButton(
//					appearance: .dark,
//					state: isSelected ? .selected : .unselected
//				)
//			}
//			.padding()
//		}
//	}
// }
// #endif
