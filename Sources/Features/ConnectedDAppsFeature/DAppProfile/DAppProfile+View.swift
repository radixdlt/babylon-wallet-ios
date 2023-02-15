import FeaturePrelude

// MARK: - View

extension DAppProfile {
	@MainActor
	public struct View: SwiftUI.View {
		let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	struct ViewState: Equatable {
		let title: String
		let showTokenList: Bool
		let showNFTList: Bool

		let addressViewState: AddressView.ViewState
		let personas: [PersonaProfileRowModel]
		let dApp: DAppProfileModel
	}
}

// MARK: - Body

public extension DAppProfile.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: .medium1) {
					DAppPlaceholder(size: .veryLarge)
						.padding(.top, .medium1)

					Separator()
						.padding(.horizontal, .medium1)

					TextBlock(viewStore.dApp.description, textStyle: .body1Regular, color: .app.gray1)
						.padding(.horizontal, .large2)

					Separator()
						.padding(.horizontal, .medium1)

					InfoBlock(store: store)
						.padding(.horizontal, .large2)

					if viewStore.showTokenList {
						TextBlock(sectionHeading: L10n.DAppProfile.tokens)
							.padding(.horizontal, .large2)
						TokenList(store: store)
					}

					if viewStore.showNFTList {
						TextBlock(sectionHeading: L10n.DAppProfile.nfts)
							.padding(.horizontal, .large2)
						NFTList(store: store)
					}

					VStack(spacing: 0) {
						TextBlock(L10n.DAppProfile.personaHeading, textStyle: .body1HighImportance, color: .app.gray2)
							.padding(.vertical, .large3)
							.padding(.horizontal, .medium1)
						PersonasList(store: store)
							.padding(.bottom, .large2)
					}
					.background(.app.gray5)

					VStack {
						RadixButton(destructive: L10n.DAppProfile.forgetDApp) {
							viewStore.send(.forgetThisDApp)
						}
						.padding([.horizontal, .bottom], .medium3)
					}
				}
				.navBarTitle(viewStore.title)
				.navigationDestination(store: store.selectedPersona) { store in
					PersonaProfile.View(store: store)
				}
			}
		}
	}
}

// MARK: - Extensions

private extension DAppProfile.State {
	var viewState: DAppProfile.ViewState {
		.init(title: name,
		      showTokenList: !dApp.tokens.isEmpty,
		      showNFTList: !dApp.nfts.isEmpty,
		      addressViewState: .init(address: dApp.address.address, format: .short),
		      personas: personas,
		      dApp: dApp)
	}
}

private extension DAppProfile.Store {
	var selectedPersona: PresentationStoreOf<PersonaProfile> {
		scope(state: \.$selectedPersona) { .child(.selectedPersona($0)) }
	}
}

// MARK: Child Views

extension DAppProfile.View {
	@MainActor
	struct InfoBlock: View {
		let store: StoreOf<DAppProfile>

		var body: some View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: .medium2) {
					HStack(spacing: 0) {
						TextBlock(sectionHeading: L10n.DAppProfile.definition)
						Spacer(minLength: 0)
						AddressView(viewStore.addressViewState, textStyle: .body1HighImportance) {
							viewStore.send(.copyAddressButtonTapped)
						}
						.foregroundColor(.app.gray1)
					}

					TextBlock(sectionHeading: L10n.DAppProfile.website)

					URLButton(url: viewStore.dApp.domain) {
						viewStore.send(.openURLTapped)
					}
				}
			}
		}
	}

	@MainActor
	struct TokenList: View {
		let store: StoreOf<DAppProfile>

		var body: some View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium3) {
					ForEach(viewStore.dApp.tokens) { token in
						RadixCard {
							PlainListRow(withChevron: false, title: token.name) {
								viewStore.send(.tokenTapped(token.id))
							} icon: {
								TokenPlaceholder(size: .small)
							}
						}
						.padding(.horizontal, .medium3)
					}
				}
			}
		}
	}

	@MainActor
	struct NFTList: View {
		let store: StoreOf<DAppProfile>

		var body: some View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium3) {
					ForEach(viewStore.dApp.nfts) { nft in
						RadixCard {
							PlainListRow(withChevron: false, title: nft.name) {
								viewStore.send(.nftTapped(nft.id))
							} icon: {
								NFTPlaceholder(size: .small)
							}
						}
						.padding(.horizontal, .medium3)
					}
				}
			}
		}
	}

	@MainActor
	struct PersonasList: View {
		let store: StoreOf<DAppProfile>

		var body: some View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium3) {
					ForEach(viewStore.personas) { persona in
						RadixCard {
							PlainListRow(title: persona.name) {
								viewStore.send(.personaTapped(persona.name))
							} icon: {
								PersonaThumbnail(persona.thumbnail)
							}
						}
						.padding(.horizontal, .medium3)
					}
				}
			}
		}
	}
}

// TODO: • Move somewhere else

public extension View {
	func navBarTitle(_ title: String) -> some View {
		toolbar {
			ToolbarItem(placement: .principal) {
				Text(title)
			}
		}
		.navigationTitle(title)
	}
}
