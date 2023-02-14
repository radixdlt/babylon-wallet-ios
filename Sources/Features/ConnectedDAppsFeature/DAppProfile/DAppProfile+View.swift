import FeaturePrelude

// MARK: - View

public extension DAppProfile {
	@MainActor
	struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	internal struct ViewState: Equatable {
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
						TokenList(store: store)
					}

					if viewStore.showNFTList {
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

private extension DAppProfile.Store {
	var selectedPersona: PresentationStoreOf<PersonaProfile> {
		scope(state: \.$selectedPersona) { .child(.selectedPersona($0)) }
	}
}

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

// MARK: Child Views

extension DAppProfile.View {
	@MainActor
	struct InfoBlock: View {
		let store: StoreOf<DAppProfile>

		var body: some View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: .medium2) {
					HStack(spacing: 0) {
						SectionHeading(L10n.DAppProfile.definition)
						Spacer(minLength: 0)
						AddressView(viewStore.addressViewState, textStyle: .body1HighImportance) {
							viewStore.send(.copyAddressButtonTapped)
						}
						.foregroundColor(.app.gray1)
					}

					SectionHeading(L10n.DAppProfile.website)

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
				SectionHeading(L10n.DAppProfile.tokens)
					.padding(.horizontal, .large2)

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
				SectionHeading(L10n.DAppProfile.nfts)
					.padding(.horizontal, .large2)

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

// MARK: - URLButton
// General purpose helper views

struct URLButton: View {
	let url: URL
	let action: () -> Void

	public var body: some View {
		Button(action: action) {
			Label {
				Text(url.absoluteString)
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.blue2)
			} icon: {
				Image(asset: AssetResource.iconLinkOut)
					.foregroundColor(.app.gray2)
			}
			.labelStyle(.trailingIcon)
		}
	}
}

// MARK: - SectionHeading
struct SectionHeading: View {
	let text: String

	init(_ text: String) {
		self.text = text
	}

	public var body: some View {
		HStack(spacing: 0) {
			Text(text)
				.textStyle(.body1Regular)
				.foregroundColor(.app.gray2)
			Spacer(minLength: 0)
		}
	}
}

// MARK: - TextBlock
// TODO: • Useful components - Move somewhere

public struct TextBlock: View {
	let text: String
	let textStyle: TextStyle
	let color: Color

	public init(_ text: String, textStyle: TextStyle = .body1Regular, color: Color = .app.gray1) {
		self.text = text
		self.textStyle = textStyle
		self.color = color
	}

	public var body: some View {
		HStack(spacing: 0) {
			Text(text)
				.textStyle(textStyle)
				.foregroundColor(color)
			Spacer(minLength: 0)
		}
	}
}

// MARK: - PersonaThumbnail
public struct PersonaThumbnail: View {
	private let url: URL

	public init(_ url: URL) {
		self.url = url
	}

	public var body: some View {
		ZStack {
			Rectangle()
				.fill(.blue)
				.clipShape(Circle())
			Circle()
				.stroke(.app.gray3, lineWidth: 1)
		}
		.frame(.small)
	}
}

// TODO: • Useful style - Move somewhere

public extension LabelStyle where Self == TrailingIconLabelStyle {
	/// Applies the `trailingIcon` style with the default spacing
	static var trailingIcon: Self { .trailingIcon() }

	/// A label style where the icon follows the "title", or text part
	static func trailingIcon(spacing: CGFloat = .small2) -> Self {
		.init(spacing: spacing)
	}
}

// MARK: - TrailingIconLabelStyle
public struct TrailingIconLabelStyle: LabelStyle {
	let spacing: CGFloat

	public func makeBody(configuration: Configuration) -> some View {
		HStack(spacing: spacing) {
			configuration.title
			configuration.icon
		}
	}
}
