import FeaturePrelude

// MARK: - LoginRequest.View
extension LoginRequest {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<LoginRequest>
	}
}

extension LoginRequest.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				VStack(spacing: .zero) {
					Spacer()
						.frame(height: .small2)

					ScrollView {
						VStack(spacing: .medium2) {
							VStack(spacing: .medium2) {
								dappImage

//								Text(titleText(with: viewStore))
//									.foregroundColor(.app.gray1)
//									.textStyle(.sheetTitle)
//
//								subtitle(
//									dappName: viewStore.dappName,
//									message: subtitleText(with: viewStore)
//								)
//								.textStyle(.secondaryHeader)
//								.multilineTextAlignment(.center)
							}
							.padding(.bottom, .medium2)

							Text(L10n.DApp.LoginRequest.chooseAPersonaTitle)
								.foregroundColor(.app.gray1)
								.textStyle(.body1Header)
								.padding(.bottom, .small2)

							ForEachStore(
								store.scope(
									state: \.personas,
									action: { .child(.persona(id: $0, action: $1)) }
								),
								content: { PersonaRow.View(store: $0) }
							)

							Spacer()
								.frame(height: .small3)

							Button(L10n.Personas.createNewPersonaButtonTitle) {
								viewStore.send(.createNewPersonaButtonTapped)
							}
							.buttonStyle(.secondaryRectangular(
								shouldExpand: false
							))

							Spacer()
								.frame(height: .large1 * 1.5)
						}
						.padding(.horizontal, .medium1)
					}

					WithControlRequirements(
						viewStore.continueButtonRequirements,
						forAction: {
							viewStore.send(.continueButtonTapped($0.persona, $0.authorizedPersona))
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

// MARK: - LoginRequest.View.LoginRequestViewStore
private extension LoginRequest.View {
	typealias LoginRequestViewStore = ComposableArchitecture.ViewStore<LoginRequest.View.ViewState, LoginRequest.ViewAction>
}

// MARK: - Private Computed Properties
private extension LoginRequest.View {
	var dappImage: some View {
		// NOTE: using placeholder until API is available
		Color.app.gray4
			.frame(.medium)
			.cornerRadius(.medium3)
	}

	// TODO: @Nikola do this in ViewState
//	func titleText(with viewStore: LoginRequestViewStore) -> String {
//		viewStore.isKnownDapp ?
//			L10n.DApp.LoginRequest.Title.knownDapp :
//			L10n.DApp.LoginRequest.Title.newDapp
//	}

	func subtitle(dappName: String, message: String) -> some View {
		var component1 = AttributedString(dappName)
		component1.foregroundColor = .app.gray1

		var component2 = AttributedString(message)
		component2.foregroundColor = .app.gray2

		return Text(component1 + component2)
	}

	// TODO: @Nikola do this in ViewState
//	func subtitleText(with viewStore: LoginRequestViewStore) -> String {

//	}
}

// MARK: - LoginRequest.View.ViewState
extension LoginRequest.View {
	struct ViewState: Equatable {
		let dappName: String
//		let isKnownDapp: Bool
		let title: String
		let subtitle: String
		let canProceed: Bool
		let continueButtonRequirements: ContinueButtonRequirements?

		struct ContinueButtonRequirements: Equatable {
			let persona: OnNetwork.Persona
			let authorizedPersona: OnNetwork.ConnectedDapp.AuthorizedPersonaSimple?
		}

		init(state: LoginRequest.State) {
			dappName = state.dappMetadata.name
			// TODO: @Nikola
			title = ""
			let isKnownDapp = state.authorizedPersona != nil
			subtitle = isKnownDapp ?
				L10n.DApp.LoginRequest.Subtitle.knownDapp :
				L10n.DApp.LoginRequest.Subtitle.newDapp
			canProceed = state.selectedPersona != nil

			if let persona = state.selectedPersona {
				continueButtonRequirements = .init(
					persona: persona,
					authorizedPersona: state.authorizedPersona
				)
			} else {
				continueButtonRequirements = nil
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - LoginRequest_Preview
struct LoginRequest_Preview: PreviewProvider {
	static var previews: some View {
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
