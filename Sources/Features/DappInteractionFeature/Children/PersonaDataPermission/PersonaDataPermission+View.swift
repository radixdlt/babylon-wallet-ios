import EditPersonaFeature
import FeaturePrelude

// MARK: - Permission.View
extension PersonaDataPermission {
	struct ViewState: Equatable {
		let title: String
		let subtitle: AttributedString
		let output: IdentifiedArrayOf<Profile.Network.Persona.Field>?

		init(state: PersonaDataPermission.State) {
			self.title = L10n.DappRequest.PersonalDataPermission.title
			self.subtitle = {
				let normalColor = Color.app.gray2
				let highlightColor = Color.app.gray1

				let dappName = AttributedString(state.dappMetadata.name.rawValue, foregroundColor: highlightColor)
				let explanation1 = AttributedString(L10n.DappRequest.AccountPermission.subtitlePart1, foregroundColor: normalColor)
				let explanation2 = AttributedString(L10n.DappRequest.AccountPermission.subtitlePart2, foregroundColor: highlightColor)
				let explanation3 = AttributedString(L10n.DappRequest.AccountPermission.subtitlePart3, foregroundColor: normalColor)

				return dappName + explanation1 + explanation2 + explanation3
			}()
			self.output = {
				guard let persona = state.persona else {
					return nil
				}
				let fields = persona.persona.fields
					.filter { state.requiredFieldIDs.contains($0.id) }
				guard fields.count == state.requiredFieldIDs.count else {
					return nil
				}
				return fields
			}()
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<PersonaDataPermission>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: PersonaDataPermission.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						DappHeader(
							icon: nil,
							title: viewStore.title,
							subtitle: viewStore.subtitle
						)

						IfLetStore(
							store.scope(
								state: \.persona,
								action: { .child(.persona($0)) }
							),
							then: { PersonaDataPermissionBox.View(store: $0) }
						)

						Text(L10n.DappRequest.AccountPermission.updateInSettingsExplanation)
							.foregroundColor(.app.gray2)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
							.padding(.horizontal, .medium2)
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
				}
				.footer {
					WithControlRequirements(
						viewStore.output,
						forAction: { viewStore.send(.continueButtonTapped($0)) }
					) { action in
						Button(L10n.Common.continue, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /PersonaDataPermission.Destinations.State.editPersona,
					action: PersonaDataPermission.Destinations.Action.editPersona,
					content: { EditPersona.View(store: $0) }
				)
				.task { viewStore.send(.task) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Permission_Preview
struct PersonaDataPermission_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		NavigationStack {
			PersonaDataPermission.View(
				store: .init(
					initialState: .previewValue,
					reducer: PersonaDataPermission()
				) {
					$0.personasClient.getPersonas = { @Sendable in
						[.previewValue0, .previewValue1]
					}
				}
			)
			#if os(iOS)
			.toolbar(.visible, for: .navigationBar)
			#endif // iOS
		}
	}
}

extension PersonaDataPermission.State {
	static let previewValue: Self = .init(
		dappMetadata: .previewValue,
		personaID: Profile.Network.Persona.previewValue0.id,
		requiredFieldIDs: [.givenName, .emailAddress]
	)
}
#endif
