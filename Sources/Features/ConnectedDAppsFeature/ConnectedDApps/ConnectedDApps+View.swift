import FeaturePrelude

// MARK: - ConnectedDApps.View
public extension ConnectedDApps {
	@MainActor
	struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	internal struct ViewState: Equatable {
		let dApps: [DAppRowModel] = [
			.init(name: "NBA Top Shot", thumbnail: .placeholder),
			.init(name: "RTFK", thumbnail: .placeholder),
			.init(name: "Nas Black", thumbnail: .placeholder),
			.init(name: "Razzlekhan", thumbnail: .placeholder),
			.init(name: "Randi Zuckerberg", thumbnail: .placeholder),
		]
	}
}

// MARK: - Body

public extension ConnectedDApps.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: 0) {
					BodyText(L10n.ConnectedDApps.body)

					Separator()

					ForEach(viewStore.dApps) { dApp in
						PlainListRow(title: dApp.name) {
							DAppPlaceholder()
						} action: {
							viewStore.send(.didSelectDApp(dApp.name))
						}
					}

					Spacer()
				}
				.padding(.horizontal, .medium3)
			}
			.navBarTitle(L10n.ConnectedDApps.title)
			.navigationDestination(store: store.selectedDApp) { store in
				ConnectedDApp.View(store: store)
			}
		}
	}
}

// MARK: - Extensions

private extension ConnectedDApps.Store {
	var selectedDApp: PresentationStoreOf<ConnectedDApp> {
		scope(state: \.$selectedDApp) { .child(.selectedDApp($0)) }
	}
}

private extension ConnectedDApps.State {
	var viewState: ConnectedDApps.ViewState {
		.init()
	}
}

// MARK: - DAppRowModel
struct DAppRowModel: Identifiable, Equatable {
	let id: UUID = .init()
	let name: String
	let thumbnail: URL
}

// MARK: - BodyText
// TODO: • Move somewhere else

public struct BodyText: View {
	private let text: String
	private let textStyle: TextStyle
	private let color: Color

	public init(_ text: String, textStyle: TextStyle = .body1HighImportance, color: Color = .app.gray2) {
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
		.padding(.vertical, .medium3)
	}
}
