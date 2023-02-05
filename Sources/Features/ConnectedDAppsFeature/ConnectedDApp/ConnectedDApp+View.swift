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
}

// MARK: - Body

// icon, name, description, associated domain name(s), maybe even associated tokens/NFTs

public extension ConnectedDApp.View {
	struct ViewState: Equatable {
		let name: String
		let personas: [DAppPersonaRowModel]
	}
	
	var body: some View {
		WithViewStore(
			store,
			observe: \.viewState,
			send: { .view($0) }
		) { viewStore in
			ScrollView {
				VStack(spacing: 0) {
					Text("A dApp called \(viewStore.name)")
						.padding(50)
						.border(.orange)
						.padding(10)
					
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
		scope(state: \.selectedPersona) { .child(.selectedPersona($0)) }
	}
}

private extension ConnectedDApp.State {
	var viewState: ConnectedDApp.View.ViewState {
		.init(name: name,
			  personas: personas)
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

// TODO: • Move somewhere else

public struct DAppPersonaCard: View {
	private let model: DAppPersonaRowModel
	
	public init(model: DAppPersonaRowModel) {
		self.model = model
	}
	
	public var body: some View {
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
				.padding(.trailing, .medium3)
		}
		.padding(.medium2)
		.background {
			VStack {
				RoundedRectangle(cornerRadius: .small1)
					.fill(.app.gray5)
					.shadow(color: .app.shadowBlack, radius: .small2, x: 0, y: .small3)
			}
		}
	}
}

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

