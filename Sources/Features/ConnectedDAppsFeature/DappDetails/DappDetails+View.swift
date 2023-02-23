import FeaturePrelude

// MARK: - View

extension DappDetails {
	@MainActor
	public struct View: SwiftUI.View {
		@Environment(\.dismiss) private var dismiss
		let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	struct ViewState: Equatable {
		let title: String
		let description: String
		let domain: String?
		let addressViewState: AddressView.ViewState
		let otherMetadata: [MetadataItem]
		let fungibleTokens: [Token]
		let nonFungibleTokens: [Token]
		let personas: [Persona]
		let isDismissed: Bool

		struct MetadataItem: Identifiable, Hashable, Sendable {
			var id: Self { self }
			let key: String
			let value: String
		}

		struct Persona: Identifiable, Hashable, Sendable {
			let id: OnNetwork.Persona.ID
			let name: String
			let thumbnail: URL
		}

		struct Token: Identifiable, Hashable, Sendable {
			var id: ComponentAddress { address }
			let name: String
			let thumbnail: URL
			let address: ComponentAddress
		}
	}
}

// MARK: - Body

public extension DappDetails.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: 0) {
					DappPlaceholder(size: .veryLarge)
						.padding(.vertical, .large2)

					InfoBlock(store: store)

					TokenList(store: store)

					NFTList(store: store)

					PersonaList(store: store)

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
				.sheet(store: store.presentedPersona) { store in
					NavigationStack {
						PersonaDetails.View(store: store)
							.navigationBarTitleDisplayMode(.inline)
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
			.onChange(of: viewStore.isDismissed) { _ in
				dismiss()
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
			.map { DappDetails.ViewState.MetadataItem(key: $0.key, value: $0.value) } ?? []

		return .init(
			title: dApp.displayName.rawValue,
			description: metadata?.description ?? L10n.DAppDetails.missingDescription,
			domain: metadata?["domain"],
			addressViewState: .init(address: dApp.dAppDefinitionAddress.address, format: .default),
			otherMetadata: otherMetadata,
			fungibleTokens: [], // TODO: Populate when we have it
			nonFungibleTokens: [], // TODO: Populate when we have it
			personas: dApp.detailedAuthorizedPersonas.map(DappDetails.ViewState.Persona.init),
			isDismissed: isDismissed
		)
	}
}

private extension DappDetails.ViewState.Persona {
	init(persona: OnNetwork.AuthorizedPersonaDetailed) {
		self.init(
			id: persona.id,
			name: persona.displayName.rawValue,
			thumbnail: .placeholder
		)
	}
}

private extension DappDetails.Store {
	var presentedPersona: PresentationStoreOf<PersonaDetails> {
		scope(state: \.$presentedPersona) { .child(.presentedPersona($0)) }
	}

	var confirmDisconnectAlert: AlertStoreOf<DappDetails.ViewAction.ConfirmDisconnectAlert> {
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
						AddressView(viewStore.addressViewState, textStyle: .body1HighImportance) {
							viewStore.send(.copyAddressButtonTapped)
						}
						.foregroundColor(.app.gray1)
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
						InfoPair(heading: item.key, item: item.value)
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
				ListWithHeading(heading: L10n.DAppDetails.tokens, elements: viewStore.state, title: \.name) { _ in
					TokenPlaceholder(size: .small)
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
				ListWithHeading(heading: L10n.DAppDetails.nfts, elements: viewStore.state, title: \.name) { _ in
					NFTPlaceholder(size: .small)
				} action: { id in
					viewStore.send(.nonFungibleTokenTapped(id))
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
	struct PersonaList: View {
		let store: StoreOf<DappDetails>

		var body: some View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				if viewStore.personas.isEmpty {
					Text(L10n.DAppDetails.noPersonasHeading)
						.sectionHeading
						.padding(.horizontal, .medium1)
						.padding(.vertical, .large3)
				} else {
					VStack(alignment: .leading, spacing: 0) {
						Text(L10n.DAppDetails.personaHeading)
							.sectionHeading
							.padding(.horizontal, .medium1)
							.padding(.vertical, .large3)

						VStack(spacing: .medium3) {
							ForEach(viewStore.personas) { persona in
								Card {
									PlainListRow(title: persona.name) {
										viewStore.send(.personaTapped(persona.id))
									} icon: {
										PersonaThumbnail(persona.thumbnail)
									}
								}
								.padding(.horizontal, .medium3)
							}
						}
					}
					.padding(.bottom, .large2)
				}
			}
			.background(.app.gray5)
		}
	}
}
