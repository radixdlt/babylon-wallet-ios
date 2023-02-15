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
				VStack(spacing: 0) {
					DAppPlaceholder(size: .veryLarge)
						.padding(.vertical, .large2)

					InfoBlock(store: store)

					TokenList(store: store)

					NFTList(store: store)

					PersonaList(store: store)

					Button(L10n.DAppProfile.forgetDApp) {
						viewStore.send(.forgetThisDApp)
					}
					.buttonStyle(.destructive)
					.padding([.horizontal, .top], .medium3)
					.padding(.bottom, .large2)
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
					Separator()

					Text(viewStore.dApp.description)
						.textType(.textBlock)

					Separator()

					HStack(spacing: 0) {
						Text(L10n.DAppProfile.definition)
							.textType(.sectionHeading)
						Spacer(minLength: 0)
						AddressView(viewStore.addressViewState, textStyle: .body1HighImportance) {
							viewStore.send(.copyAddressButtonTapped)
						}
						.foregroundColor(.app.gray1)
					}

					Text(L10n.DAppProfile.website)
						.textType(.sectionHeading)

					Button(viewStore.dApp.domain.absoluteString) {
						viewStore.send(.openURLTapped)
					}
					.buttonStyle(.url)
				}
				.padding(.horizontal, .medium1)
				.padding(.bottom, .large2)
			}
		}
	}

	@MainActor
	struct TokenList: View {
		let store: StoreOf<DAppProfile>

		var body: some View {
			WithViewStore(store, observe: \.dApp.tokens, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.DAppProfile.tokens,
				                elements: viewStore.state,
				                title: \.name) { _ in
					TokenPlaceholder(size: .small)
				} action: { id in
					viewStore.send(.tokenTapped(id))
				}
			}
		}
	}

	@MainActor
	struct NFTList: View {
		let store: StoreOf<DAppProfile>

		var body: some View {
			WithViewStore(store, observe: \.dApp.nfts, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.DAppProfile.nfts,
				                elements: viewStore.state,
				                title: \.name) { _ in
					NFTPlaceholder(size: .small)
				} action: { id in
					viewStore.send(.nftTapped(id))
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
					Text(L10n.DAppProfile.nfts)
						.textType(.sectionHeading)
						.padding(.horizontal, .medium1)

					ForEach(elements) { element in
						RadixCard {
							PlainListRow(withChevron: false, title: title(element)) {
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
		let store: StoreOf<DAppProfile>

		var body: some View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: 0) {
					Text(L10n.DAppProfile.personaHeading)
						.textType(.sectionHeading)
						.padding(.horizontal, .medium1)
						.padding(.vertical, .large3)

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
				.padding(.bottom, .large2)
				.background(.app.gray5)
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
