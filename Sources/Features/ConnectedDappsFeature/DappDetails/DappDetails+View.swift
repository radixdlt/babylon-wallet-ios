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

	struct ViewState: Equatable {
		let title: String
		let description: Loadable<String?>
		let domain: String?
		let addressViewState: AddressView.ViewState
		let personas: [Persona]

		struct Persona: Identifiable, Hashable, Sendable {
			let id: OnNetwork.Persona.ID
			let name: String
			let thumbnail: URL
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
					.buttonStyle(.destructive)
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
			}
		}
	}
}

// MARK: - Extensions

private extension DappDetails.State {
	var viewState: DappDetails.ViewState {
		.init(title: dApp.displayName.rawValue,
		      description: $metadata.description,
		      domain: metadata?.domain,
		      addressViewState: .init(address: dApp.dAppDefinitionAddress.address, format: .short),
		      personas: dApp.detailedAuthorizedPersonas.map(DappDetails.ViewState.Persona.init))
	}
}

private extension DappDetails.ViewState.Persona {
	init(persona: OnNetwork.AuthorizedPersonaDetailed) {
		self.init(id: persona.id,
		          name: persona.displayName.rawValue,
		          thumbnail: .placeholder)
	}
}

private extension DappDetails.Store {
	var presentedPersona: PresentationStoreOf<PersonaDetails> {
		scope(state: \.$presentedPersona) { .child(.presentedPersona($0)) }
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

					LoadableView(viewStore.description) { description in
						Text(description ?? L10n.DAppDetails.missingDescription)
							.textBlock
							.italic(description == nil)
						Separator()
					}

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

						if let url = URL(string: domain) {
							Button(domain) {
								viewStore.send(.openURLTapped(url))
							}
							.buttonStyle(.url)
						} else {
							Text(domain)
								.urlLink
						}
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
			WithViewStore(store, observe: \.dApp.tokens, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.DAppDetails.tokens, elements: viewStore.state, title: \.name) { _ in
					TokenPlaceholder(size: .small)
				} action: { id in
					viewStore.send(.tokenTapped(id))
				}
			}
		}
	}

	@MainActor
	struct NFTList: View {
		let store: StoreOf<DappDetails>

		var body: some View {
			WithViewStore(store, observe: \.dApp.nfts, send: { .view($0) }) { viewStore in
				ListWithHeading(heading: L10n.DAppDetails.nfts, elements: viewStore.state, title: \.name) { _ in
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
					Text(heading)
						.sectionHeading
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
								RadixCard {
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

// TODO: • Move somewhere else

extension OnNetwork.ConnectedDappDetailed {
	var tokens: [TokenModel] {
		[.mock("NBA"), .mock("NAS")]
	}

	var nfts: [TokenModel] {
		[.mock("NBA top shot"), .mock("NAS RTFK")]
	}
}

// MARK: - TokenModel
public struct TokenModel: Identifiable, Hashable, Sendable {
	public let id: UUID = .init()
	let name: String
	let address: ComponentAddress = .mock

	static func mock(_ name: String) -> Self {
		.init(name: name)
	}
}

// MARK: - NFTModel
public struct NFTModel: Identifiable, Hashable, Sendable {
	public let id: UUID = .init()
	let name: String
	let address: ComponentAddress = .mock

	static func mock(_ name: String) -> Self {
		.init(name: name)
	}
}

extension String {
	static let nbaTopShot: String = "NBA Top Shot is a decentralized application that provides users with the opportunity to purchase, collect, and showcase digital blockchain collectibles"

	static let lorem: String = "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt."
}

extension ComponentAddress {
	static let mock = ComponentAddress(address: "component_sim1qfh2n5twmrzrlstqepsu3u624r4pdzca9pqhrcy7624sfmxzep")
}

// MARK: - LoadableView
struct LoadableView<Value, Content: View>: View {
	let value: Loadable<Value>
	let content: (Value) -> Content

	public init(_ value: Loadable<Value>, @ViewBuilder content: @escaping (Value) -> Content) {
		self.value = value
		self.content = content
	}

	var body: some View {
		switch value {
		case .notLoaded:
			Color.gray // Shimmer?
		case .loading:
			Color.orange // Animated shimmer?
		case let .loaded(value):
			content(value)
		case .failed:
			Color.red // Error message?
		}
	}
}
