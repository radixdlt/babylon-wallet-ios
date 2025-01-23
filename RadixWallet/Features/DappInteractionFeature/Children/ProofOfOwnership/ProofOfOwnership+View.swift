import SwiftUI

// MARK: - ProofOfOwnership.View
extension ProofOfOwnership {
	struct View: SwiftUI.View {
		let store: StoreOf<ProofOfOwnership>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .medium2) {
						DappHeader(
							thumbnail: store.dappMetadata.thumbnail,
							title: store.title,
							subtitle: store.subtitle
						)

						switch store.kind {
						case .persona:
							if let viewState = store.personaViewState {
								PersonaRow.View(viewState: viewState, mode: .display)
							}
						case .accounts:
							VStack(spacing: .small1) {
								ForEach(store.accounts) { account in
									AccountCard(kind: .details, account: account)
								}
							}
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
			}
		}
	}
}

private extension ProofOfOwnership.State {
	var title: String {
		switch kind {
		case .persona:
			L10n.DAppRequest.PersonaProofOfOwnership.title
		case .accounts:
			L10n.DAppRequest.AccountsProofOfOwnership.title
		}
	}

	var subtitle: String {
		switch kind {
		case .persona:
			L10n.DAppRequest.PersonaProofOfOwnership.subtitle(dappMetadata.name)
		case .accounts:
			L10n.DAppRequest.AccountsProofOfOwnership.subtitle(dappMetadata.name)
		}
	}

	var personaViewState: PersonaRow.ViewState? {
		guard let persona else {
			return nil
		}
		return .init(state: .init(persona: persona, lastLogin: nil))
	}
}
