import FeaturePrelude
import Profile

extension EditPersona.State {
	var viewState: EditPersona.ViewState {
		.init(
			avatarURL: avatarURL,
			output: { () -> EditPersona.Output? in
				guard
					let personaLabelInput = labelField.input,
					let personaLabelOutput = NonEmptyString(rawValue: personaLabelInput.trimmed())
				else {
					return nil
				}
				var fieldsOutput: IdentifiedArrayOf<Profile.Network.Persona.Field> = []
				for field in dynamicFields {
					guard
						let fieldInput = field.input,
						let fieldOutput = NonEmptyString(rawValue: fieldInput.trimmed())
					else {
						return nil
					}
					fieldsOutput[id: field.id] = .init(id: field.id, value: fieldOutput)
				}
				return EditPersona.Output(personaLabel: personaLabelOutput, fields: fieldsOutput)
			}()
		)
	}
}

// MARK: - EditPersonaDetails.View
extension EditPersona {
	public struct ViewState: Equatable {
		let avatarURL: URL
		let output: Output?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersona>

		public init(store: StoreOf<EditPersona>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				NavigationStack {
					ScrollView(showsIndicators: false) {
						VStack(spacing: .medium1) {
							PersonaThumbnail(viewStore.avatarURL, size: .veryLarge)

							EditPersonaStaticField.View(
								store: store.scope(
									state: \.labelField,
									action: { .child(.labelField($0)) }
								)
							)

							Separator()

							ForEachStore(
								store.scope(
									state: \.dynamicFields,
									action: { .child(.dynamicField(id: $0, action: $1)) }
								),
								content: { EditPersonaDynamicField.View(store: $0) }
							)

							Button(action: { viewStore.send(.addAFieldButtonTapped) }) {
								Text(L10n.EditPersona.Button.addAField).padding(.horizontal, .medium2)
							}
							.buttonStyle(.secondaryRectangular)
							.padding(.top, .medium2)
						}
						.padding(.horizontal, .medium1)
						.padding(.bottom, .medium1)
					}
					#if os(iOS)
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							Button(L10n.EditPersona.Button.cancel, action: { viewStore.send(.cancelButtonTapped) })
								.textStyle(.body1Link)
								.foregroundColor(.app.blue2)
						}
						ToolbarItem(placement: .navigationBarTrailing) {
							WithControlRequirements(viewStore.output, forAction: { viewStore.send(.saveButtonTapped($0)) }) { action in
								Button(L10n.EditPersona.Button.save, action: action)
									.textStyle(.body1Link)
									.foregroundColor(.app.blue2)
									.opacity(viewStore.output == nil ? 0.3 : 1)
							}
						}
					}
					#endif
				}
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /EditPersona.Destinations.State.addFields,
					action: EditPersona.Destinations.Action.addFields,
					content: { EditPersonaAddFields.View(store: $0) }
				)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - EditPersonaDetails_Preview
struct EditPersona_Preview: PreviewProvider {
	static var previews: some View {
		EditPersona.View(
			store: .init(
				initialState: .previewValue(
					mode: .dapp(
						requiredFieldIDs: [
							.givenName,
							.emailAddress,
						]
					)
				),
				reducer: EditPersona()
			)
		)
		.previewDisplayName("dApp Mode")

		EditPersona.View(
			store: .init(
				initialState: .previewValue(mode: .edit),
				reducer: EditPersona()
			)
		)
		.previewDisplayName("Edit Mode")
	}
}

extension EditPersona.State {
	public static func previewValue(mode: EditPersona.State.Mode) -> Self {
		.init(
			mode: mode,
			avatarURL: URL(string: "something")!,
			personaLabel: NonEmptyString(rawValue: "RadIpsum")!,
			existingFields: [
				.init(id: .givenName, value: "Lorem"),
				.init(id: .familyName, value: "Ipsum"),
				.init(id: .emailAddress, value: "lorem.ipsum@example.com"),
				.init(id: .phoneNumber, value: "555-5555"),
			]
		)
	}
}
#endif
