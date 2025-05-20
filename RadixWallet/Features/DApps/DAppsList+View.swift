import SwiftUI

// MARK: - DAppsList.View
extension DAppsList {
	struct View: SwiftUI.View {
		let store: StoreOf<DAppsList>

		var body: some SwiftUI.View {
			loadable(store.dAppDetails) { dApps in
				VStack(spacing: .small1) {
					ForEach(dApps) { dApp in
						Card {
							store.send(.view(.didSelectDapp(dApp.id)))
						} contents: {
							VStack(alignment: .leading, spacing: .zero) {
								PlainListRow(
									context: .dappAndPersona,
									title: dApp.name,
									subtitle: dApp.description,
									icon: {
										Thumbnail(.dapp, url: dApp.thumbnail)
									}
								)

								if dApp.hasClaim {
									StatusMessageView(text: L10n.AuthorizedDapps.pendingDeposit, type: .warning, useNarrowSpacing: true)
										.padding(.horizontal, .medium1)
										.padding(.bottom, .medium3)
								}
							}
						}
					}
				}
				.animation(.easeInOut, value: dApps)
			}
		}
	}
}
