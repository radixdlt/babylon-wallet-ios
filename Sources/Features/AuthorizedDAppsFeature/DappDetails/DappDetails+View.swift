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
		let domain: String?
		let thumbnail: URL?
		let address: DappDefinitionAddress
		let otherMetadata: [MetadataItem]
		let fungibleTokens: [State.Tokens.ResourceDetails]?
		let nonFungibleTokens: [State.Tokens.ResourceDetails]?
		let hasPersonas: Bool

		struct MetadataItem: Identifiable, Hashable, Sendable {
			var id: Self { self }
			let key: String
			let value: String
		}
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

					TokenList(store: store)

					NFTList(store: store)

					Personas(store: store, hasPersonas: viewStore.hasPersonas)
						.background(.app.gray5)

					Button(L10n.DAppDetails.forgetDapp) {
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
				.sheet(store: store.personaDetails) { store in
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
				.alert(store: store.confirmDisconnectAlert)
			}
		}
	}
}

// MARK: - Extensions

private extension DappDetails.State {
	var viewState: DappDetails.ViewState {
		let ignoredKeys: Set<String> = ["description", "domain", "name"]

		let otherMetadata = metadata?.items
			.filter { !ignoredKeys.contains($0.key) }
			.compactMap { item in
				item.value.asString.map {
					DappDetails.ViewState.MetadataItem(key: item.key, value: $0)
				}
			} ?? []

		return .init(
			title: dApp.displayName.rawValue,
			description: metadata?.description ?? L10n.DAppDetails.missingDescription,
			domain: metadata?.domain,
			thumbnail: metadata?.iconURL,
			address: dApp.dAppDefinitionAddress,
			otherMetadata: otherMetadata,
			fungibleTokens: tokens?.fungible,
			nonFungibleTokens: tokens?.nonFungible,
			hasPersonas: !personaList.personas.isEmpty
		)
	}
}

private extension DappDetails.Store {
	var personaDetails: PresentationStoreOf<PersonaDetails> {
		scope(state: \.$personaDetails) { .child(.personaDetails($0)) }
	}

	var confirmDisconnectAlert: AlertPresentationStore<DappDetails.ViewAction.ConfirmDisconnectAlert> {
		scope(state: \.$confirmDisconnectAlert) { .view(.confirmDisconnectAlert($0)) }
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
						Text(L10n.DAppDetails.definition)
							.sectionHeading

						Spacer(minLength: 0)

						AddressView(.address(.account(viewStore.address)))
							.foregroundColor(.app.gray1)
							.textStyle(.body1HighImportance)
					}

					if let domain = viewStore.domain {
						Text(L10n.DAppDetails.website)
							.sectionHeading
						Button(domain) {
							if let url = URL(string: domain) {
								viewStore.send(.openURLTapped(url))
							}
						}
						.buttonStyle(.url)
					}

					ForEach(viewStore.otherMetadata) { item in
						VPair(heading: item.key, item: item.value)
					}
				}
				.padding(.horizontal, .medium1)
				.padding(.bottom, .large2)
			}
		}
	}

	@MainActor
	struct TokenList: View {
		let store: StoreOf<DappDetails>

		var body: some View {
			WithViewStore(store, observe: \.viewState.fungibleTokens, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.DAppDetails.tokens, elements: viewStore.state, title: \.name) { token in
					TokenThumbnail(.known(token.iconURL), size: .small)
				} action: { id in
					viewStore.send(.fungibleTokenTapped(id))
				}
			}
		}
	}

	@MainActor
	struct NFTList: View {
		let store: StoreOf<DappDetails>

		var body: some View {
			WithViewStore(store, observe: \.viewState.nonFungibleTokens, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.DAppDetails.nfts, elements: viewStore.state, title: \.name) { token in
					NFTThumbnail(token.iconURL, size: .small)
				} action: { id in
					viewStore.send(.nonFungibleTokenTapped(id))
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
							PlainListRow(showChevron: false, title: title(element)) {
								action(element.id)
							} icon: {
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
				Text(L10n.DAppDetails.personaHeading)
					.sectionHeading
					.flushedLeft
					.padding(.horizontal, .medium1)
					.padding(.vertical, .small2)

				Separator()
					.padding(.bottom, .small2)

				let personasStore = store.scope(state: \.personaList) { .child(.personas($0)) }
				PersonaListCoreView(store: personasStore)
			} else {
				Text(L10n.DAppDetails.noPersonasHeading)
					.sectionHeading
					.flushedLeft
					.padding(.horizontal, .medium1)
					.padding(.vertical, .small2)
			}
		}
	}
}
