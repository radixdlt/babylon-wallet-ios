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
		let name: String
		let addressViewState: AddressView.ViewState
		let personas: [PersonaProfileRowModel]
		let dApp: DAppProfileModel
	}
}

// MARK: - Body

public extension DAppProfile.View {
	var body: some View {
		WithViewStore(store.actionless, observe: \.name) { viewStore in
			ScrollView {
				VStack(alignment: .leading, spacing: 0) {
					Header(store: store)
					TokenList(store: store)
					NFTList(store: store)
					VStack(spacing: .medium3) {
						BodyText(L10n.DAppProfile.personaHeading, textStyle: .body1HighImportance, color: .app.gray2)
							.padding(.vertical, .large3)
						PersonasList(store: store)
					}
				}
				.padding(.top, .medium1)
				.padding(.horizontal, .medium3)
				.navBarTitle(viewStore.state)
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
		.init(name: name,
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
	struct Header: View {
		let store: StoreOf<DAppProfile>
	}

	@MainActor
	struct TokenList: View {
		let store: StoreOf<DAppProfile>
	}

	@MainActor
	struct NFTList: View {
		let store: StoreOf<DAppProfile>
	}

	@MainActor
	struct PersonasList: View {
		let store: StoreOf<DAppProfile>
	}
}

extension DAppProfile.View.Header {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			VStack(spacing: .medium1) {
				DAppPlaceholder(size: .veryLarge)
				//				.padding(.bottom, .small2)
				Separator()
					.padding(.horizontal, .medium1)
				Text(viewStore.dApp.description)
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray1)
					.padding(.horizontal, .large2)
				Separator()
					.padding(.horizontal, .medium1)
				VStack(alignment: .leading, spacing: .medium3) {
					HStack(spacing: 0) {
						Text(L10n.DAppProfile.definition)
							.textStyle(.body1Regular)
							.foregroundColor(.app.gray2)
						Spacer(minLength: 0)
						AddressView(viewStore.addressViewState, textStyle: .body1HighImportance) {
							viewStore.send(.copyAddressButtonTapped)
						}
						.foregroundColor(.app.gray1)
					}
					Text(L10n.DAppProfile.website)
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray2)
					Button {
						viewStore.send(.openURLTapped)
					} label: {
						Label {
							Text(viewStore.dApp.domain.absoluteString)
								.textStyle(.body1HighImportance)
								.foregroundColor(.app.blue2)
						} icon: {
							Image(asset: AssetResource.iconLinkOut)
						}
					}
				}
			}
		}
	}
}

extension LabelStyle where Self == TrailingIconLabelStyle {
	/// Applies the `trailingIcon` style with the default spacing
	static var trailingIcon: Self { .trailingIcon() }

	/// A label style where the icon follows the "title", or text part
	static func trailingIcon(spacing: CGFloat = .small2) -> Self {
		.init(spacing: spacing)
	}
}

// MARK: - TrailingIconLabelStyle
struct TrailingIconLabelStyle: LabelStyle {
	let spacing: CGFloat

	func makeBody(configuration: Configuration) -> some View {
		HStack(spacing: spacing) {
			configuration.title
			configuration.icon
		}
	}
}

extension DAppProfile.View.TokenList {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			if !viewStore.dApp.tokens.isEmpty {
				Text(L10n.DAppProfile.tokens)
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray2)
				VStack(spacing: .medium3) {
					ForEach(viewStore.dApp.tokens) { token in
						RadixCard {
							PlainListRow(withChevron: false, title: token.name) {
								viewStore.send(.tokenTapped(token.id))
							} icon: {
								TokenPlaceholder(size: .small)
							}
						}
					}
				}
			}
		}
	}
}

extension DAppProfile.View.NFTList {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			if !viewStore.dApp.nfts.isEmpty {
				Text(L10n.DAppProfile.tokens)
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray2)
				VStack(spacing: .medium3) {
					ForEach(viewStore.dApp.nfts) { nft in
						RadixCard {
							PlainListRow(withChevron: false, title: nft.name) {
								viewStore.send(.nftTapped(nft.id))
							} icon: {
								NFTPlaceholder(size: .small)
							}
						}
					}
				}
			}
		}
	}
}

extension DAppProfile.View.PersonasList {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			VStack(spacing: .medium3) {
				ForEach(viewStore.personas) { persona in
					Button {
						viewStore.send(.personaSelected(persona.name))
					} label: {
						RadixCard {
							PersonaProfileCard(model: persona)
								.padding(.medium3)
						}
					}
				}
			}
		}
	}
}

// MARK: - PersonaProfileCard
struct PersonaProfileCard: View {
	let model: PersonaProfileRowModel

	var body: some View {
		HStack(spacing: 0) {
			VStack(spacing: 0) {
				PersonaThumbnail(model.thumbnail)
				Spacer()
			}
			.padding(.trailing, .medium3)
			VStack(alignment: .leading, spacing: 0) {
				Text(model.name)
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray1)
					.padding(.bottom, 6)
				Text(model.sharingStatus)
					.textStyle(.body2Header)
					.foregroundColor(.app.gray2)
					.padding(.bottom, 6)
				Group {
					Text("\(model.personalDataCount) pieces of personal data")
						.padding(.bottom, 4)
					Text("\(model.accountCount) accounts")
				}
				.textStyle(.body2Regular)
				.foregroundColor(.app.gray2)
			}
			Spacer()
			RadixChevron()
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
