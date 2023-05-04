import CreateEntityFeature
import FeaturePrelude

// MARK: - LoginRequest.View
extension Login {
	struct ViewState: Equatable {
		let title: String
		let subtitle: AttributedString
		let shouldShowChooseAPersonaTitle: Bool
		let availablePersonas: IdentifiedArrayOf<PersonaRow.State>
		let selectedPersona: PersonaRow.State?
		let continueButtonRequirements: ContinueButtonRequirements?

		struct ContinueButtonRequirements: Equatable {
			let persona: Profile.Network.Persona
		}

		init(state: Login.State) {
			let isKnownDapp = state.authorizedPersona != nil

			title = isKnownDapp
				? L10n.DApp.Login.Title.knownDapp
				: L10n.DApp.Login.Title.newDapp

			subtitle = {
				let dappName = AttributedString(state.dappMetadata.name.rawValue, foregroundColor: .app.gray1)

				let explanation = AttributedString(
					isKnownDapp ? L10n.DApp.Login.Subtitle.knownDapp : L10n.DApp.Login.Subtitle.newDapp,
					foregroundColor: .app.gray2
				)

				return dappName + explanation
			}()

			shouldShowChooseAPersonaTitle = !state.personas.isEmpty

			availablePersonas = state.personas
			selectedPersona = state.selectedPersona

			if let persona = state.selectedPersona {
				continueButtonRequirements = .init(persona: persona.persona)
			} else {
				continueButtonRequirements = nil
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
							icon: nil,
							title: viewStore.title,
							subtitle: viewStore.subtitle
						)

						if viewStore.shouldShowChooseAPersonaTitle {
							Text(L10n.DApp.Login.chooseAPersonaTitle)
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

						Button(L10n.Personas.createNewPersonaButtonTitle) {
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
						Button(L10n.DApp.Login.continueButtonTitle, action: action)
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
						.dependency(\.authorizedDappsClient, .previewValueOnePersona())
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
		dappDefinitionAddress: try! .init(address: "DappDefinitionAddress"),
		dappMetadata: .previewValue, loginRequest: try! .init(challenge: .init(HexCodable32Bytes(.deadbeef32Bytes)))
	)
}
#endif
