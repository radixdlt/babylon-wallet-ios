import EditPersonaFeature
import FeaturePrelude

extension PersonaDataPermissionBox.State {
	var viewState: PersonaDataPermissionBox.ViewState {
		.init(
			avatarURL: URL(string: "something")!,
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
							L10n.DApp.PersonaDataPermission.requiredInformation.text.bold()
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
		let avatarURL: URL
		let personaLabel: String
		let existingRequiredFields: String?
		let missingRequiredFields: Hint?
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<PersonaDataPermissionBox>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				DappPermissionBox {
					HStack(spacing: .medium2) {
						PersonaThumbnail(viewStore.avatarURL, size: .small)
						Text(viewStore.personaLabel)
							.foregroundColor(.app.gray1)
							.textStyle(.secondaryHeader)
					}
				} content: {
					VStack(alignment: .leading, spacing: .small1) {
						if let existingRequiredFields = viewStore.existingRequiredFields {
							Text(existingRequiredFields)
								.foregroundColor(.app.gray2)
								.textStyle(.body2Regular)
						}

						viewStore.missingRequiredFields

						Button(L10n.DApp.PersonaDataPermission.Button.edit) {
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
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct PersonaDataPermissionBox_PreviewProvider: PreviewProvider {
	static var previews: some View {
		PersonaDataPermissionBox.View(
			store: Store(
				initialState: .init(
					persona: .previewValue0,
					requiredFieldIDs: [.givenName, .emailAddress]
				),
				reducer: PersonaDataPermissionBox()
			)
		)
		.padding()
	}
}
#endif
