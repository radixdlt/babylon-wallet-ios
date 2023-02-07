import FeaturePrelude

// MARK: - LoginRequest.View
extension LoginRequest {
	struct ViewState: Equatable {
		let title: String
		let subtitle: AttributedString
		let canProceed: Bool
		let continueButtonRequirements: ContinueButtonRequirements?

		struct ContinueButtonRequirements: Equatable {
			let persona: OnNetwork.Persona
		}

		init(state: LoginRequest.State) {
			let isKnownDapp = state.authorizedPersona != nil

			title = isKnownDapp ?
				L10n.DApp.LoginRequest.Title.knownDapp :
				L10n.DApp.LoginRequest.Title.newDapp

			subtitle = {
				let dappName = AttributedString(state.dappMetadata.name, foregroundColor: .app.gray1)

				let explanation = AttributedString(
					isKnownDapp ?
						L10n.DApp.LoginRequest.Subtitle.knownDapp :
						L10n.DApp.LoginRequest.Subtitle.newDapp,
					foregroundColor: .app.gray2
				)

				return dappName + explanation
			}()

			canProceed = state.selectedPersona != nil

			if let persona = state.selectedPersona {
				continueButtonRequirements = .init(persona: persona)
			} else {
				continueButtonRequirements = nil
			}
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<LoginRequest>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: LoginRequest.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				ForceFullScreen {
					ScrollView {
						VStack(spacing: .medium2) {
							VStack(spacing: .medium2) {
								dappImage

								Text(viewStore.title)
									.foregroundColor(.app.gray1)
									.textStyle(.sheetTitle)

								Text(viewStore.subtitle)
									.textStyle(.secondaryHeader)
									.multilineTextAlignment(.center)
							}
							.padding(.bottom, .small2)

							Text(L10n.DApp.LoginRequest.chooseAPersonaTitle)
								.foregroundColor(.app.gray1)
								.textStyle(.body1Header)

							ForEachStore(
								store.scope(
									state: \.personas,
									action: { .child(.persona(id: $0, action: $1)) }
								),
								content: { PersonaRow.View(store: $0) }
							)

							Button(L10n.Personas.createNewPersonaButtonTitle) {
								viewStore.send(.createNewPersonaButtonTapped)
							}
							.buttonStyle(.secondaryRectangular(
								shouldExpand: false
							))
						}
						.padding(.horizontal, .medium1)
						.padding(.bottom, .large1 * 1.5)
					}
					.safeAreaInset(edge: .bottom) {
						WithControlRequirements(
							viewStore.continueButtonRequirements,
							forAction: {
								viewStore.send(.continueButtonTapped($0.persona))
							}
						) { action in
							ConfirmationFooter(
								title: L10n.DApp.LoginRequest.continueButtonTitle,
								isEnabled: viewStore.canProceed,
								action: action
							)
						}
					}
				}
				.onAppear {
					viewStore.send(.appeared)
				}
			}
		}
	}
}

// MARK: - Private Computed Properties
private extension LoginRequest.View {
	var dappImage: some SwiftUI.View {
		// NOTE: using placeholder until API is available
		Color.app.gray4
			.frame(.medium)
			.cornerRadius(.medium3)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - LoginRequest_Preview
struct LoginRequest_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		LoginRequest.View(
			store: .init(
				initialState: .previewValue,
				reducer: LoginRequest()
					.dependency(\.profileClient, .previewValueTwoPersonas)
			)
		)
	}
}

extension LoginRequest.State {
	static let previewValue: Self = .init(
		dappDefinitionAddress: try! .init(address: "DappDefinitionAddress"),
		dappMetadata: .previewValue
	)
}
#endif
