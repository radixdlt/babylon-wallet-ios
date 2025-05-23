//
//  DAppsListView.swift
//  RadixWallet
//
//  Created by Ghenadie VP on 19.05.2025.
//
import SargonUniFFI

struct DAppsListView: View {
	struct DApp: Equatable, Identifiable {
		typealias ID = DappDefinitionAddress
		let id: ID
		let name: String
		let thumbnail: URL?
		let description: String?
		let hasClaim: Bool
	}

	let dApps: IdentifiedArrayOf<DApp>
	let selection: (DApp.ID) -> Void

	var body: some View {
		VStack(spacing: .small1) {
			ForEach(dApps) { dApp in
				Card {
					selection(dApp.id)
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
