import EditPersonaFeature
import FeaturePrelude

extension PersonaDataPermissionBox.State {
	var viewState: PersonaDataPermissionBox.ViewState {
		.init(
			personaLabel: persona.displayName.rawValue,
			existingRequiredFields: {
				var existingRequiredFields = persona.fields.filter { allRequiredFieldIDs.contains($0.id) }

				let name = [
					existingRequiredFields.remove(id: .givenName)?.value.rawValue,
					existingRequiredFields.remove(id: .familyName)?.value.rawValue,
				]
				.compacted()
				.joined(separator: " ")
				.nilIfBlank

				let otherFields = existingRequiredFields
					.sorted(by: { $0.id < $1.id })
					.map(\.value.rawValue)

				if let allFields = ([name].compacted() + otherFields).nilIfEmpty {
					return allFields.joined(separator: "\n")
				} else {
					return nil
				}
			}(),
			missingRequiredFields: { () -> Hint? in
				if let missingRequiredFieldIDs {
					return .error {
						Text {
							L10n.DApp.PersonaDataBox.requiredInformation.text.bold()
							" "
							missingRequiredFieldIDs.sorted().map(\.title.localizedLowercase).joined(separator: ", ")
						}
					}
				} else {
					return nil
				}
			}()
		)
	}
}

extension PersonaDataPermissionBox {
	struct ViewState: Equatable {
		let personaLabel: String
		let existingRequiredFields: String?
		let missingRequiredFields: Hint?
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
						if let existingRequiredFields = viewStore.existingRequiredFields {
							Text(existingRequiredFields)
								.foregroundColor(.app.gray2)
								.textStyle(.body2Regular)
						}

						viewStore.missingRequiredFields

						Button(L10n.DApp.PersonaDataBox.Button.edit) {
							viewStore.send(.editButtonTapped)
						}
						.modifier {
							if viewStore.missingRequiredFields != nil {
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

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct PersonaDataPermissionBox_PreviewProvider: PreviewProvider {
	static var previews: some View {
		WithState(initialValue: false) { $isSelected in
			PersonaDataPermissionBox.View(
				store: Store(
					initialState: .init(
						persona: .previewValue0,
						requiredFieldIDs: [.givenName, .emailAddress]
					),
					reducer: PersonaDataPermissionBox()
				),
				action: { isSelected.toggle() }
			) {
				RadioButton(
					appearance: .dark,
					state: isSelected ? .selected : .unselected
				)
			}
			.padding()
		}
	}
}
#endif
