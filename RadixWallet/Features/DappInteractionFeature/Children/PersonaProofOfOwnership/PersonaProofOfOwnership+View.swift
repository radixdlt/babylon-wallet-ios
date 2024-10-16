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
				.destinations(with: store)
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
	var destination: PresentationStoreOf<PersonaProofOfOwnership.Destination> {
		func scopeState(state: State) -> PresentationState<PersonaProofOfOwnership.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<PersonaProofOfOwnership>) -> some View {
		let destinationStore = store.destination
		return sheet(store: destinationStore.scope(state: \.signing, action: \.signing)) {
			Signing.View(store: $0)
		}
	}
}
