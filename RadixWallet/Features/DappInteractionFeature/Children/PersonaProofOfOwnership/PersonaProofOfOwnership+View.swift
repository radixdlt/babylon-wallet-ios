import SwiftUI

// MARK: - PersonaProofOfOwnership.View
extension PersonaProofOfOwnership {
	struct View: SwiftUI.View {
		let store: StoreOf<PersonaProofOfOwnership>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .medium2) {
						DappHeader(
							thumbnail: store.dappMetadata.thumbnail,
							title: L10n.DAppRequest.PersonaProofOfOwnership.title,
							subtitle: L10n.DAppRequest.PersonaProofOfOwnership.subtitle(store.dappMetadata.name)
						)

						if let viewState = store.personaViewState {
							PersonaRow.View(viewState: viewState, mode: .display)
						}
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
				}
				.footer {
					Button(L10n.Common.continue) {
						store.send(.view(.continueButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
				}
				.task { store.send(.view(.task)) }
				.signProofOfOwnership(store: store.signature)
			}
		}
	}
}

private extension PersonaProofOfOwnership.State {
	var personaViewState: PersonaRow.ViewState? {
		guard let persona else {
			return nil
		}
		return .init(state: .init(persona: persona, lastLogin: nil))
	}
}

private extension StoreOf<PersonaProofOfOwnership> {
	var signature: StoreOf<SignProofOfOwnership> {
		scope(state: \.signature, action: \.child.signature)
	}
}
