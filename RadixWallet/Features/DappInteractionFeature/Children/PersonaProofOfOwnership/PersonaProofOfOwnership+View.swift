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
							title: "Verify Persona Login",
							subtitle: "**\(store.dappMetadata.name)** is requesting verification of your login with the following Persona."
						)

						if let viewState = store.personaViewState {
							PersonaRow.View(viewState: viewState, isSelected: nil) {}
						}
					}
				}
				.task { store.send(.view(.task)) }
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
