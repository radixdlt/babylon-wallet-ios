import ComposableArchitecture
import SwiftUI
extension PersonaDataPermission.State {
	var viewState: PersonaDataPermission.ViewState {
		.init(
			thumbnail: dappMetadata.thumbnail,
			title: L10n.DAppRequest.PersonalDataPermission.title,
			subtitle: L10n.DAppRequest.PersonalDataPermission.subtitle(dappMetadata.name),
			output: persona?.responseValidation.response
		)
	}
}

// MARK: - Permission.View
extension PersonaDataPermission {
	struct ViewState: Equatable {
		let thumbnail: URL?
		let title: String
		let subtitle: String
		let output: P2P.Dapp.Request.Response?
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<PersonaDataPermission>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						DappHeader(
							thumbnail: viewStore.thumbnail,
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

						Text(L10n.DAppRequest.AccountPermission.updateInSettingsExplanation)
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
						Button(L10n.DAppRequest.PersonalDataPermission.continue, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
			}
			.task {
				store.send(.view(.task))
			}
			.destinations(with: store)
		}
	}
}

private extension StoreOf<PersonaDataPermission> {
	var destination: PresentationStoreOf<PersonaDataPermission.Destination_> {
		scope(state: \.$destination) { .destination($0) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<PersonaDataPermission>) -> some View {
		let destinationStore = store.destination
		return sheet(
			store: destinationStore,
			state: /PersonaDataPermission.Destination_.State.editPersona,
			action: PersonaDataPermission.Destination_.Action.editPersona,
			content: { EditPersona.View(store: $0) }
		)
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - Permission_Preview
struct PersonaDataPermission_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		NavigationStack {
			PersonaDataPermission.View(
				store: .init(
					initialState: .previewValue,
					reducer: PersonaDataPermission.init
				) {
					$0.personasClient.getPersonas = { @Sendable in
						[.previewValue0, .previewValue1]
					}
				}
			)
			.toolbar(.visible, for: .navigationBar)
		}
	}
}

extension PersonaDataPermission.State {
	static let previewValue: Self = .init(
		dappMetadata: .previewValue,
		personaID: Profile.Network.Persona.previewValue0.id,
		requested: .init(
			isRequestingName: true,
			numberOfRequestedEmailAddresses: .atLeast(1),
			numberOfRequestedPhoneNumbers: nil
		)
	)
}
#endif
