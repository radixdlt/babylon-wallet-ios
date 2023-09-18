import AssetsFeature
import FeaturePrelude

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
		let associatedDapps: [State.AssociatedDapp]?
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
					DappThumbnail(.known(viewStore.thumbnail), size: .veryLarge)
						.padding(.vertical, .large2)

					InfoBlock(store: store)

					FungiblesList(store: store)

					NonFungiblesListList(store: store)

					let personasStore = store.scope(state: \.personaList) { .child(.personas($0)) }
					Personas(store: personasStore, tappablePersonas: viewStore.tappablePersonas)
						.background(.app.gray5)

					if viewStore.showForgetDapp {
						Button(L10n.AuthorizedDapps.ForgetDappAlert.title) {
							viewStore.send(.forgetThisDappTapped)
						}
						.buttonStyle(.primaryRectangular(isDestructive: true))
						.padding([.horizontal, .top], .medium3)
						.padding(.bottom, .large2)
					}
				}
				.onAppear {
					viewStore.send(.appeared)
				}
				.navigationTitle(viewStore.title)
				.navigationDestination(
					store: store.destination,
					state: /DappDetails.Destination.State.personaDetails,
					action: DappDetails.Destination.Action.personaDetails,
					destination: { PersonaDetails.View(store: $0) }
				)
				.sheet(
					store: store.destination,
					state: /DappDetails.Destination.State.fungibleDetails,
					action: DappDetails.Destination.Action.fungibleDetails
				) {
					FungibleTokenDetails.View(store: $0)
				}
				.sheet(
					store: store.destination,
					state: /DappDetails.Destination.State.nonFungibleDetails,
					action: DappDetails.Destination.Action.nonFungibleDetails
				) {
					NonFungibleTokenDetails.View(store: $0)
				}
				.alert(
					store: store.destination,
					state: /DappDetails.Destination.State.confirmDisconnectAlert,
					action: DappDetails.Destination.Action.confirmDisconnectAlert
				)
			}
		}
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

extension OnLedgerEntity.Resource {
	var title: String {
		name ?? symbol ?? L10n.DAppRequest.Metadata.unknownName
	}
}

private extension StoreOf<DappDetails> {
	var destination: PresentationStoreOf<DappDetails.Destination> {
		scope(state: \.$destination, action: { .child(.destination($0)) })
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
					TokenThumbnail(.known(resource.iconURL), size: .small)
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
					NFTThumbnail(resource.iconURL, size: .small)
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

					PersonaListCoreView(store: store, tappable: tappablePersonas)
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
