import SwiftUI

// MARK: - AccountsProofOfOwnership.View
extension AccountsProofOfOwnership {
	struct View: SwiftUI.View {
		let store: StoreOf<AccountsProofOfOwnership>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .medium2) {
						DappHeader(
							thumbnail: store.dappMetadata.thumbnail,
							title: "Verify Account Ownership",
							subtitle: "**\(store.dappMetadata.name)** is requesting verification that you own the following Account(s)."
						)

						VStack(spacing: .small1) {
							ForEach(store.accounts) { account in
								AccountCard(kind: .details, account: account)
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
				.destinations(with: store)
			}
		}
	}
}

private extension StoreOf<AccountsProofOfOwnership> {
	var destination: PresentationStoreOf<AccountsProofOfOwnership.Destination> {
		func scopeState(state: State) -> PresentationState<AccountsProofOfOwnership.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<AccountsProofOfOwnership>) -> some View {
		let destinationStore = store.destination
		return sheet(store: destinationStore.scope(state: \.signing, action: \.signing)) {
			Signing.View(store: $0)
		}
	}
}
