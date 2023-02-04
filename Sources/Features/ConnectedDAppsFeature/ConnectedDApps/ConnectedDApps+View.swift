import FeaturePrelude

// MARK: - View

public extension ConnectedDApps {
    @MainActor
    struct View: SwiftUI.View {
        private let store: Store

        public init(store: Store) {
            self.store = store
        }
    }
}

// MARK: - Body

public extension ConnectedDApps.View {
	struct ViewState: Equatable {
		let dApps: [DAppRowModel] = [
			.init(name: "NBA Top Shot", thumbnail: .placeholder),
			.init(name: "RTFK", thumbnail: .placeholder),
			.init(name: "Nas Black", thumbnail: .placeholder),
			.init(name: "Razzlekhan", thumbnail: .placeholder),
			.init(name: "Randi Zuckerberg", thumbnail: .placeholder)
		]
	}
	
	var body: some View {
		ForceFullScreen {
			WithViewStore(
				store,
				observe: \.viewState,
				send: { .view($0) }
			) { viewStore in
				VStack(spacing: .zero) {
					NavigationBar(
						titleText: L10n.ConnectedDApps.title,
						leadingItem: BackButton {
							viewStore.send(.dismissButtonTapped)
						}
					)
					.foregroundColor(.app.gray1)
					.padding(.horizontal, .small2)
					.frame(height: .navBarHeight)
					ScrollView {
						VStack(spacing: 0) {
							Separator()
							
							ForEach(viewStore.dApps) { dApp in
								PlainListRow(dApp.name, icon: Rectangle().fill(.orange), verySmall: false) {
									viewStore.send(.didTapDApp(dApp.name))
								}
							}
							.padding(.horizontal, .medium3)
							
							Spacer()
						}
					}
				}
			}
		}
		.overlay {
			IfLetStore(store.destination) { destinationStore in
				ConnectedDApp.View(store: destinationStore)
			}
		}
	}
}
	
	// MARK: - Extensions

extension ConnectedDApps.State {
	var viewState: ConnectedDApps.View.ViewState {
		.init()
	}
}

struct DAppRowModel: Identifiable, Equatable {
	let id: UUID = .init()
	let name: String
	let thumbnail: URL
}
