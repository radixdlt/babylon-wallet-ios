import FeaturePrelude

// MARK: - View

public extension ConnectedDApp {
	@MainActor
	struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	internal struct ViewState: Equatable {
		let name: String
		let personas: [DAppPersonaRowModel]
		let dApp: ConnectedDAppModel
	}
}

// MARK: - Body

public extension ConnectedDApp.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(alignment: .leading, spacing: 0) {
					ConnectedDAppHeader(model: viewStore.dApp)

					BodyText(L10n.ConnectedDApp.body)

					VStack(spacing: .medium3) {
						ForEach(viewStore.personas) { persona in
							Button {
								viewStore.send(.didSelectPersona(persona.name))
							} label: {
								DAppPersonaCard(model: persona)
							}
						}
					}
					Spacer()
				}
				.padding(.horizontal, .medium3)
				.navBarTitle(viewStore.name)
				.navigationDestination(store: store.selectedPersona) { store in
					DAppPersona.View(store: store)
				}
			}
		}
	}
}

// MARK: - Extensions

private extension ConnectedDApp.Store {
	var selectedPersona: PresentationStoreOf<DAppPersona> {
		scope(state: \.$selectedPersona) { .child(.selectedPersona($0)) }
	}
}

private extension ConnectedDApp.State {
	var viewState: ConnectedDApp.ViewState {
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

// MARK: - ConnectedDAppHeader
// TODO: • Move somewhere else

struct ConnectedDAppHeader: View {
	let model: ConnectedDAppModel

	var body: some View {
		VStack(alignment: .leading, spacing: .small2) {
			HStack(alignment: .top, spacing: .small2) {
				DAppPlaceholder(large: true)

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
				Spacer(minLength: 0)
			}
			.padding(.top, .medium3)

			BodyText(model.description)

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

// MARK: - DAppPersonaCard
struct DAppPersonaCard: View {
	let model: DAppPersonaRowModel

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
			Image(asset: AssetResource.chevronRight)
				.foregroundColor(.app.gray1)
				.padding(.trailing, 2)
		}
		.padding(.medium2)
		.background {
			VStack {
				RoundedRectangle(cornerRadius: .small1)
					.fill(.app.gray5)
					.shadow(color: .app.shadowBlack, radius: .small2, x: .zero, y: .small2)
			}
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
