import FeaturePrelude
import PersonaDetailsFeature
import PersonasFeature

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
		let description: String
		let domain: URL?
		let thumbnail: URL?
		let address: DappDefinitionAddress
		let fungibles: [State.Resources.ResourceDetails]?
		let nonFungibles: [State.Resources.ResourceDetails]?
		let associatedDapps: [State.AssociatedDapp]?
		let hasPersonas: Bool
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

					Personas(store: store, hasPersonas: viewStore.hasPersonas)
						.background(.app.gray5)

					Button(L10n.AuthorizedDapps.ForgetDappAlert.title) {
						viewStore.send(.forgetThisDappTapped)
					}
					.buttonStyle(.primaryRectangular(isDestructive: true))
					.padding([.horizontal, .top], .medium3)
					.padding(.bottom, .large2)
				}
				.onAppear {
					viewStore.send(.appeared)
				}
				.navigationTitle(viewStore.title)
				.sheet(
					store: store.destination,
					state: /DappDetails.Destination.State.personaDetails,
					action: DappDetails.Destination.Action.personaDetails
				) { store in
					NavigationStack {
						PersonaDetails.View(store: store)
						#if os(iOS)
							.navigationBarTitleDisplayMode(.inline)
						#endif
							.toolbar {
								ToolbarItem(placement: .primaryAction) {
									CloseButton {
										viewStore.send(.dismissPersonaTapped)
									}
								}
							}
					}
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
			title: dApp.displayName.rawValue,
			description: metadata?.description ?? L10n.AuthorizedDapps.DAppDetails.missingDescription,
			domain: metadata?.claimedWebsites?.first,
			thumbnail: metadata?.iconURL,
			address: dApp.dAppDefinitionAddress,
			fungibles: resources?.fungible,
			nonFungibles: resources?.nonFungible,
			associatedDapps: associatedDapps,
			hasPersonas: !personaList.personas.isEmpty
		)
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

					Text(viewStore.description)
						.textBlock
						.flushedLeft

					Separator()

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
//						Button(domain.stringValue) {
//							viewStore.send(.openURLTapped(domain))
//						}
//						.buttonStyle(.url)
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
			WithViewStore(store, observe: \.viewState.fungibles, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.AuthorizedDapps.DAppDetails.tokens, elements: viewStore.state, title: \.name) { resource in
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
			WithViewStore(store, observe: \.viewState.nonFungibles, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.AuthorizedDapps.DAppDetails.nfts, elements: viewStore.state, title: \.name) { resource in
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
		let elements: [Element]?
		let title: (Element) -> String
		let icon: (Element) -> Icon
		let action: (Element.ID) -> Void

		var body: some View {
			if let elements, !elements.isEmpty {
				VStack(alignment: .leading, spacing: .medium3) {
					Text(heading)
						.sectionHeading
						.padding(.horizontal, .medium1)

					ForEach(elements) { element in
						Card {
							action(element.id)
						} contents: {
							PlainListRow(showChevron: false, title: title(element)) {
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
		let store: StoreOf<DappDetails>
		let hasPersonas: Bool

		var body: some View {
			if hasPersonas {
				Text(L10n.AuthorizedDapps.DAppDetails.personasHeading)
					.sectionHeading
					.flushedLeft
					.padding(.horizontal, .medium1)
					.padding(.vertical, .small2)

				Separator()
					.padding(.bottom, .small2)

				let personasStore = store.scope(state: \.personaList) { .child(.personas($0)) }
				PersonaListCoreView(store: personasStore)
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
