import EditPersonaFeature
import FeaturePrelude

extension PersonaDataPermissionBox.State {
	var viewState: PersonaDataPermissionBox.ViewState {
		.init(
			personaLabel: persona.displayName.rawValue,
			existingRequiredEntries:
			persona.personaData.existingRequestEntries(requested)
				.sorted(by: \.discriminator)
				.map(\.description)
				.nilIfEmpty?
				.joined(separator: "\n"),

			missingRequiredEntries: { () -> Hint? in
				switch response {
				case .success:
					return nil
				case let .failure(error):
					return .error {
						Text {
							"Issues:".text.bold() // FIXME: Strings
							" "
							error.issues.keys.sorted().map(\.title.localizedLowercase).joined(separator: ", ")
							//						L10n.DAppRequest.PersonalDataBox.requiredInformation.text.bold()
							//						" "
							//						missingRequiredFieldIDs.sorted().map(\.title.localizedLowercase).joined(separator: ", ")
						}
					}
				}
			}()
		)
	}
}

// FIXME: This could also be a requirement in BasePersonaDataEntryProtocol
extension PersonaData.Entry {
	var description: String {
		switch self {
		case let .name(name):
			return name.description
		case let .dateOfBirth(dateOfBirth):
			return dateOfBirth.description
		case let .companyName(companyName):
			return companyName.description
		case let .emailAddress(emailAddress):
			return emailAddress.description
		case let .phoneNumber(phoneNumber):
			return phoneNumber.description
		case let .url(associatedURL):
			return associatedURL.description
		case let .postalAddress(postalAddress):
			return postalAddress.description
		case let .creditCard(creditCard):
			return creditCard.description
		}
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
//					reducer: PersonaDataPermissionBox()
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
