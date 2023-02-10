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
		let personas: [PersonaProfileRowModel]
		let dApp: DAppProfileModel
	}
}

// MARK: - Body

public extension DAppProfile.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(alignment: .leading, spacing: 0) {
					DAppProfileHeader(model: viewStore.dApp)

					BodyText(L10n.ConnectedDApp.body)

					VStack(spacing: .medium3) {
						ForEach(viewStore.personas) { persona in
							Button {
								viewStore.send(.didSelectPersona(persona.name))
							} label: {
								RadixCard {
									PersonaProfileCard(model: persona)
								}
							}
						}
					}
					Spacer()
				}
				.padding(.top, .medium1)
				.padding(.horizontal, .medium3)
				.navBarTitle(viewStore.name)
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
		      personas: personas,
		      dApp: dApp)
	}
}

// TODO: • Move somewhere else

public extension View {
	func navBarTitle(_ title: String) -> some View {
		self.toolbar {
			ToolbarItem(placement: .principal) {
				Text(title)
			}
		}
		.navigationTitle(title)
	}
}

// MARK: - DAppProfileHeader
// TODO: • Move somewhere else

struct DAppProfileHeader: View {
	let model: DAppProfileModel

	var body: some View {
		VStack(spacing: .medium1) {
			DAppPlaceholder(size: .veryLarge)
			//				.padding(.bottom, .small2)
			Separator()
				.padding(.horizontal, .medium1)
			Text(model.description)
				.textStyle(.body1Regular)
				.foregroundColor(.app.gray1)
				.padding(.horizontal, .large2)
			Separator()
				.padding(.horizontal, .medium1)
			VStack(spacing: .medium3) {
				HStack(spacing: 0) {
					Text("•• dApp definition")
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray2)
					Spacer(minLength: 0)
					Text("•• dApp definition")
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray2)
				}
			}

			if model.domainNames.count > 0 {
				VStack(alignment: .leading, spacing: 0) {
					Text(L10n.ConnectedDApp.domainsHeading)
						.textStyle(.body2HighImportance)
						.padding(.bottom, .small2)
					VStack(alignment: .leading, spacing: .small3) {
						ForEach(model.domainNames, id: \.self) { domainName in
							Text(domainName)
								.textStyle(.body2Header)
								.foregroundColor(.app.gray2)
						}
					}
				}
			}
			.padding(.top, .medium3)

			if model.tokens > 0 {
				Text(L10n.ConnectedDApp.tokensHeading)
					.textStyle(.body2HighImportance)
					.padding(.bottom, .small2)
				let columns: [GridItem] = [GridItem(.adaptive(minimum: .large1), spacing: .small2)]
				let tokens = 0 ..< model.tokens
				LazyVGrid(columns: columns, spacing: .small2) {
					ForEach(tokens, id: \.self) { _ in
						NFTPlaceholder()
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
