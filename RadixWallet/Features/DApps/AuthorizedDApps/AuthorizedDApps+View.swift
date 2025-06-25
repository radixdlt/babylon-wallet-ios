import ComposableArchitecture
import SwiftUI

// MARK: - AuthorizedDappsFeature.View
extension AuthorizedDappsFeature {
	@MainActor
	struct View: SwiftUI.View {
		private let store: Store

		init(store: Store) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				DAppsFiltering.View(store: store.scope(state: \.filtering, action: \.child.filtering))
					.padding(.top, .small3)
					.padding(.bottom, .small1)
					.background(.primaryBackground)

				ScrollView {
					VStack(alignment: .leading, spacing: .medium1) {
						loadable(viewStore.displayedDapps) { categorizedDapps in
							ForEach(categorizedDapps) { category in
								Section {
									VStack {
										ForEach(category.dApps) { dApp in
											Card {
												viewStore.send(.view(.didSelectDapp(dApp.id)))
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

													if viewStore.dappsWithClaims.contains(dApp.id) {
														StatusMessageView(text: L10n.AuthorizedDapps.pendingDeposit, type: .warning, useNarrowSpacing: true)
															.padding(.horizontal, .medium1)
															.padding(.bottom, .medium3)
													}

													if !dApp.tags.isEmpty {
														FlowLayout {
															ForEach(dApp.tags, id: \.self) {
																AssetTagView(tag: $0)
															}
														}
														.padding(.horizontal, .medium1)
														.padding(.vertical, .medium3)
														.background(.tertiaryBackground)
													}
												}
											}
										}
									}
								} header: {
									Text(category.category.title).textStyle(.sectionHeader)
										.flushedLeft
								}
							}
						}
					}
					.padding(.vertical, .small1)
					.padding(.horizontal, .medium3)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(.secondaryBackground)
				.destinations(with: store)
				.task {
					viewStore.send(.view(.task))
				}
			}
		}
	}
}

// MARK: - Extensions

private extension StoreOf<AuthorizedDappsFeature> {
	var destination: PresentationStoreOf<AuthorizedDappsFeature.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<AuthorizedDappsFeature>) -> some View {
		let destinationStore = store.destination
		return navigationDestination(store: destinationStore.scope(state: \.presentedDapp, action: \.presentedDapp)) {
			DappDetails.View(store: $0)
		}
	}
}
