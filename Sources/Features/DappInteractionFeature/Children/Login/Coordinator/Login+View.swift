import CreatePersonaFeature
import FeaturePrelude

// MARK: - LoginRequest.View
extension Login {
	struct ViewState: Equatable {
		let thumbnail: URL?
		let title: String
		let subtitle: String
		let showChoosePersonaTitle: Bool
		let availablePersonas: IdentifiedArrayOf<PersonaRow.State>
		let selectedPersona: PersonaRow.State?
		let continueButtonRequirements: ContinueButtonRequirements?

		struct ContinueButtonRequirements: Equatable {
			let persona: Profile.Network.Persona
		}

		init(state: Login.State) {
			let isKnownDapp = state.authorizedPersona != nil

			self.thumbnail = state.dappMetadata.thumbnail

			self.title = isKnownDapp
				? L10n.DAppRequest.Login.titleKnownDapp
				: L10n.DAppRequest.Login.titleNewDapp

			let dAppName = state.dappMetadata.name
			self.subtitle = isKnownDapp
				? L10n.DAppRequest.Login.subtitleKnownDapp(dAppName)
				: L10n.DAppRequest.Login.subtitleNewDapp(dAppName)

			self.showChoosePersonaTitle = !state.personas.isEmpty

			self.availablePersonas = state.personas
			self.selectedPersona = state.selectedPersona

			if let persona = state.selectedPersona {
				self.continueButtonRequirements = .init(persona: persona.persona)
			} else {
				self.continueButtonRequirements = nil
			}
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<Login>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: Login.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						DappHeader(
							thumbnail: viewStore.thumbnail,
							title: viewStore.title,
							subtitle: viewStore.subtitle
						)

						if viewStore.showChoosePersonaTitle {
							Text(L10n.DAppRequest.Login.choosePersona)
								.foregroundColor(.app.gray1)
								.textStyle(.body1Header)
						}

						VStack(spacing: .small1) {
							Selection(
								viewStore.binding(
									get: \.selectedPersona,
									send: { .selectedPersonaChanged($0) }
								),
								from: viewStore.availablePersonas
							) { item in
								PersonaRow.View(
									viewState: .init(state: item.value),
									isSelected: item.isSelected,
									action: item.action
								)
							}
						}

						Button(L10n.Personas.createNewPersona) {
							viewStore.send(.createNewPersonaButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: false))
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
				}
				.footer {
					WithControlRequirements(
						viewStore.continueButtonRequirements,
						forAction: { viewStore.send(.continueButtonTapped($0.persona)) }
					) { action in
						Button(L10n.DAppRequest.Login.continue, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.onAppear {
					viewStore.send(.appeared)
				}
				.sheet(
					store: store.scope(
						state: \.$createPersonaCoordinator,
						action: { .child(.createPersonaCoordinator($0)) }
					),
					content: { CreatePersonaCoordinator.View(store: $0) }
				)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - LoginRequest_Preview
struct Login_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		NavigationStack {
			Login.View(
				store: .init(
					initialState: .previewValue,
					reducer: Login()
						.dependency(\.accountsClient, .previewValueTwoAccounts())
						// FIXME: fix previews with PersonaData
//						.dependency(\.authorizedDappsClient, .previewValueOnePersona())
						.dependency(\.personasClient, .previewValueTwoPersonas(existing: true))
						.dependency(\.personasClient, .previewValueTwoPersonas(existing: false))
				)
			)
			#if os(iOS)
			.toolbar(.visible, for: .navigationBar)
			#endif // iOS
		}
	}
}

extension Login.State {
	static let previewValue: Self = .init(
		dappMetadata: .previewValue,
		loginRequest: try! .withChallenge(.init(challenge: .init(rawValue: .init(.deadbeef32Bytes))))
	)
}
#endif
