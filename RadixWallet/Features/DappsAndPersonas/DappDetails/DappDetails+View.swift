import ComposableArchitecture
import SwiftUI

// MARK: - View

extension DappDetails {
	@MainActor
	public struct View: SwiftUI.View {
		let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	public struct ViewState: Equatable {
		let title: String
		let description: String?
		let domain: URL?
		let thumbnail: URL?
		let address: DappDefinitionAddress
		let associatedDapps: [OnLedgerEntity.AssociatedDapp]?
		let showForgetDapp: Bool
		let tappablePersonas: Bool
	}
}

// MARK: - Body

extension DappDetails.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: 0) {
					Thumbnail(.dapp, url: viewStore.thumbnail, size: .veryLarge)
						.padding(.vertical, .large2)

					InfoBlock(store: store)

					FungiblesList(store: store)

					NonFungiblesListList(store: store)

					Personas(store: store.personas, tappablePersonas: viewStore.tappablePersonas)
						.background(.app.gray5)

					if viewStore.showForgetDapp {
						Button(L10n.AuthorizedDapps.ForgetDappAlert.title) {
							store.send(.view(.forgetThisDappTapped))
						}
						.buttonStyle(.primaryRectangular(isDestructive: true))
						.padding([.horizontal, .top], .medium3)
						.padding(.bottom, .large2)
					}
				}
				.navigationTitle(viewStore.title)
			}
		}
		.onAppear {
			store.send(.view(.appeared))
		}
		.destinations(with: store)
	}
}

private extension StoreOf<DappDetails> {
	var destination: PresentationStoreOf<DappDetails.Destination> {
		func scopeState(state: State) -> PresentationState<DappDetails.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
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
			domain: metadata?.claimedWebsites?.first,
			thumbnail: metadata?.iconURL,
			address: dAppDefinitionAddress,
			associatedDapps: associatedDapps,
			showForgetDapp: context != .general,
			tappablePersonas: context == .settings(.authorizedDapps)
		)
	}

	var fungibles: [OnLedgerEntity.Resource] {
		resources?.fungible.elements ?? []
	}

	var nonFungibles: [OnLedgerEntity.Resource] {
		resources?.nonFungible.elements ?? []
	}
}

private extension OnLedgerEntity.Resource {
	var title: String {
		metadata.name ?? metadata.symbol ?? L10n.TransactionReview.unknown
	}
}

// MARK: Child Views

extension DappDetails.View {
	@MainActor
	struct InfoBlock: View {
		let store: StoreOf<DappDetails>

		var body: some View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: .medium2) {
					Separator()

					if let description = viewStore.description {
						Text(description)
							.textBlock
							.flushedLeft

						Separator()
					}

					HStack(spacing: 0) {
						Text(L10n.AuthorizedDapps.DAppDetails.dAppDefinition)
							.sectionHeading

						Spacer(minLength: 0)

						AddressView(.address(.account(viewStore.address)))
							.foregroundColor(.app.gray1)
							.textStyle(.body1HighImportance)
					}

					if let domain = viewStore.domain {
						Text(L10n.AuthorizedDapps.DAppDetails.website)
							.sectionHeading

						Button(domain.absoluteString) {
							viewStore.send(.openURLTapped(domain))
						}
						.buttonStyle(.url)
					}
				}
				.padding(.horizontal, .medium1)
				.padding(.bottom, .large2)
			}
		}
	}

	@MainActor
	struct FungiblesList: View {
		let store: StoreOf<DappDetails>

		var body: some View {
			WithViewStore(store, observe: \.fungibles, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.AuthorizedDapps.DAppDetails.tokens, elements: viewStore.state, title: \.title) { resource in
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
				ListWithHeading(heading: L10n.AuthorizedDapps.DAppDetails.nfts, elements: viewStore.state, title: \.title) { resource in
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
		let title: (Element) -> String
		let icon: (Element) -> Icon
		let action: (Element.ID) -> Void

		var body: some View {
			if !elements.isEmpty {
				VStack(alignment: .leading, spacing: .medium3) {
					Text(heading)
						.sectionHeading
						.padding(.horizontal, .medium1)

					ForEach(elements) { element in
						Card {
							action(element.id)
						} contents: {
							PlainListRow(title: title(element), accessory: nil) {
								icon(element)
							}
						}
						.padding(.horizontal, .medium3)
					}
				}
				.padding(.bottom, .medium1)
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
				if viewStore.hasPersonas {
					Text(L10n.AuthorizedDapps.DAppDetails.personasHeading)
						.sectionHeading
						.flushedLeft
						.padding(.horizontal, .medium1)
						.padding(.vertical, .small2)

					Separator()
						.padding(.bottom, .small2)

					PersonaListCoreView(store: store, tappable: tappablePersonas, showShield: false)
				} else {
					Text(L10n.AuthorizedDapps.DAppDetails.noPersonasHeading)
						.sectionHeading
						.flushedLeft
						.padding(.horizontal, .medium1)
						.padding(.vertical, .small2)
				}
			}
		}
	}
}
