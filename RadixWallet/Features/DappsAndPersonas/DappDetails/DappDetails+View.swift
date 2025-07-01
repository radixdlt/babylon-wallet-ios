import ComposableArchitecture
import SwiftUI

// MARK: - View

extension DappDetails {
	@MainActor
	struct View: SwiftUI.View {
		let store: Store

		init(store: Store) {
			self.store = store
		}
	}

	struct ViewState: Equatable {
		let title: String
		let description: String?
		let domain: URL?
		let thumbnail: URL?
		let address: DappDefinitionAddress
		let associatedDapps: [OnLedgerEntity.AssociatedDapp]?
		let showConfiguration: Bool
		let tappablePersonas: Bool
		let isDepositsVisible: Bool
		let hasResources: Bool
		let tags: [OnLedgerTag]
	}
}

// MARK: - Body

extension DappDetails.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: .medium1) {
					Thumbnail(.dapp, url: viewStore.thumbnail, size: .veryLarge)
						.padding(.top, .medium1)
						.padding(.bottom, .small2)

					InfoBlock(store: store)

					VStack(spacing: .medium1) {
						Separator()
						FungiblesList(store: store)
						NonFungiblesListList(store: store)
						if viewStore.hasResources {
							Separator()
						}
						Personas(store: store.personas, tappablePersonas: viewStore.tappablePersonas)
					}
					.background(.secondaryBackground)

					if viewStore.showConfiguration {
						Configuration(store: store)
					}
				}
				.radixToolbar(title: viewStore.title)
			}
			.background(.primaryBackground)
		}
		.onAppear {
			store.send(.view(.appeared))
		}
		.destinations(with: store)
	}
}

private extension StoreOf<DappDetails> {
	var destination: PresentationStoreOf<DappDetails.Destination> {
		scope(state: \.$destination, action: \.destination)
	}

	var personas: StoreOf<PersonaList> {
		scope(state: \.personaList) { .child(.personaList($0)) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<DappDetails>) -> some View {
		let destinationStore = store.destination
		return personaDetails(with: destinationStore)
			.fungibleDetails(with: destinationStore)
			.nonFungibleDetails(with: destinationStore)
			.confirmDisconnectAlert(with: destinationStore)
	}

	private func personaDetails(with destinationStore: PresentationStoreOf<DappDetails.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DappDetails.Destination.State.personaDetails,
			action: DappDetails.Destination.Action.personaDetails,
			destination: { PersonaDetails.View(store: $0) }
		)
	}

	private func fungibleDetails(with destinationStore: PresentationStoreOf<DappDetails.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /DappDetails.Destination.State.fungibleDetails,
			action: DappDetails.Destination.Action.fungibleDetails,
			content: { FungibleTokenDetails.View(store: $0) }
		)
	}

	private func nonFungibleDetails(with destinationStore: PresentationStoreOf<DappDetails.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /DappDetails.Destination.State.nonFungibleDetails,
			action: DappDetails.Destination.Action.nonFungibleDetails,
			content: { NonFungibleTokenDetails.View(store: $0) }
		)
	}

	private func confirmDisconnectAlert(with destinationStore: PresentationStoreOf<DappDetails.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /DappDetails.Destination.State.confirmDisconnectAlert,
			action: DappDetails.Destination.Action.confirmDisconnectAlert
		)
	}
}

// MARK: - Extensions

private extension DappDetails.State {
	var viewState: DappDetails.ViewState {
		.init(
			title: authorizedDapp?.displayName?.rawValue ?? metadata?.name ?? L10n.DAppRequest.Metadata.unknownName,
			description: metadata?.description,
			domain: mainWebsite,
			thumbnail: metadata?.iconURL,
			address: dAppDefinitionAddress,
			associatedDapps: associatedDapps,
			showConfiguration: context != .general,
			tappablePersonas: context == .settings(.dAppsList),
			isDepositsVisible: authorizedDapp?.isDepositsVisible ?? true,
			hasResources: resources?.isEmpty == false,
			tags: metadata?.tags ?? []
		)
	}

	var fungibles: [OnLedgerEntity.Resource] {
		resources?.fungible.elements ?? []
	}

	var nonFungibles: [OnLedgerEntity.Resource] {
		resources?.nonFungible.elements ?? []
	}
}

// MARK: Child Views

extension DappDetails.View {
	@MainActor
	struct InfoBlock: View {
		let store: StoreOf<DappDetails>

		var body: some View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					Separator()

					if let description = viewStore.description {
						Text(description)
							.textStyle(.body1Regular)
							.foregroundColor(.primaryText)
							.multilineTextAlignment(.leading)
							.padding(.horizontal, .small2)

						Separator()
					}

					VStack(alignment: .leading, spacing: .medium3) {
						KeyValueView(key: L10n.AuthorizedDapps.DAppDetails.dAppDefinition) {
							AddressView(.address(.account(viewStore.address)), imageColor: .secondaryText)
						}

						if let domain = viewStore.domain {
							KeyValueUrlView(key: L10n.AuthorizedDapps.DAppDetails.website, url: domain, isLocked: false)
						}

						OnLedgerTagsView(tags: viewStore.tags)
					}
				}
				.padding(.horizontal, .medium1)
			}
		}
	}

	@MainActor
	struct FungiblesList: View {
		let store: StoreOf<DappDetails>

		var body: some View {
			WithViewStore(store, observe: \.fungibles, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.AuthorizedDapps.DAppDetails.tokens, elements: viewStore.state, title: \.metadata.title) { resource in
					Thumbnail(token: .other(resource.metadata.iconURL), size: .small)
				} action: { id in
					viewStore.send(.fungibleTapped(id))
				}
			}
		}
	}

	@MainActor
	struct NonFungiblesListList: View {
		let store: StoreOf<DappDetails>

		var body: some View {
			WithViewStore(store, observe: \.nonFungibles, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.AuthorizedDapps.DAppDetails.nfts, elements: viewStore.state, title: \.metadata.title) { resource in
					Thumbnail(.nft, url: resource.metadata.iconURL, size: .small)
				} action: { id in
					viewStore.send(.nonFungibleTapped(id))
				}
			}
		}
	}

	@MainActor
	struct ListWithHeading<Element: Identifiable, Icon: View>: View {
		let heading: String
		let elements: [Element]
		let title: (Element) -> String?
		let icon: (Element) -> Icon
		let action: (Element.ID) -> Void

		var body: some View {
			if !elements.isEmpty {
				VStack(alignment: .leading, spacing: .medium3) {
					Text(heading)
						.textStyle(.body1Regular)
						.foregroundColor(.secondaryText)
						.padding(.horizontal, .medium3)

					ForEach(elements) { element in
						Card {
							action(element.id)
						} contents: {
							PlainListRow(title: title(element) ?? "", accessory: nil) {
								icon(element)
							}
						}
					}
				}
				.padding(.horizontal, .medium3)
			}
		}
	}

	@MainActor
	struct Personas: View {
		struct ViewState: Equatable {
			let hasPersonas: Bool

			init(state: PersonaList.State) {
				self.hasPersonas = !state.personas.isEmpty
			}
		}

		let store: StoreOf<PersonaList>
		let tappablePersonas: Bool

		var body: some View {
			WithViewStore(store, observe: ViewState.init) { viewStore in
				VStack(spacing: .medium3) {
					if viewStore.hasPersonas {
						Text(L10n.AuthorizedDapps.DAppDetails.personasHeading)
							.textBlock
							.flushedLeft
							.padding(.horizontal, .small2)

						PersonaListCoreView(store: store, tappable: tappablePersonas, showShield: false)
							.padding(.top, .small1)

					} else {
						Text(L10n.AuthorizedDapps.DAppDetails.noPersonasHeading)
							.textBlock
							.flushedLeft
							.padding(.horizontal, .small2)
					}
				}
				.padding(.horizontal, .medium3)
				.padding(.bottom, .large1)
			}
		}
	}

	@MainActor
	struct Configuration: View {
		let store: StoreOf<DappDetails>

		var body: some View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .large2) {
					VStack(spacing: .medium1) {
						ToggleView(
							title: L10n.AuthorizedDapps.DAppDetails.depositsTitle,
							subtitle: viewStore.isDepositsVisible ? L10n.AuthorizedDapps.DAppDetails.depositsVisible : L10n.AuthorizedDapps.DAppDetails.depositsHidden,
							minHeight: .zero,
							isOn: viewStore.binding(
								get: \.isDepositsVisible,
								send: { .depositsVisibleToggled($0) }
							)
						)

						Separator()
					}
					.padding(.horizontal, .small2)

					Button(L10n.AuthorizedDapps.DAppDetails.forgetDapp) {
						store.send(.view(.forgetThisDappTapped))
					}
					.buttonStyle(.primaryRectangular(isDestructive: true))
				}
				.padding(.horizontal, .medium3)
				.padding(.bottom, .medium1)
			}
		}
	}
}
