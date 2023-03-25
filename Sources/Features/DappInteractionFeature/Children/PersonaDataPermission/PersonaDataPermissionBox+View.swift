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
				guard let missingRequiredFieldIDs else { return nil }

				return Hint(
					.error,
					Text(L10n.DApp.PersonaDataPermission.requiredInformation).bold() +
						Text(" ") +
						Text(missingRequiredFieldIDs.sorted().map(\.title.localizedLowercase).joined(separator: ", "))
				)
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
		private let store: StoreOf<PersonaDataPermissionBox>

		public init(store: StoreOf<PersonaDataPermissionBox>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
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

						Button("Edit") {
							viewStore.send(.editButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
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
					requiredFieldIDs: [.givenName, .emailAddress, .phoneNumber]
				),
				reducer: PersonaDataPermissionBox()
			)
		)
		.padding()
	}
}
#endif
