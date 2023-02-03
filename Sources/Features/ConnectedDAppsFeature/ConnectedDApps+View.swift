import FeaturePrelude

// MARK: - ConnectedDApps.View

public extension ConnectedDApps {
    @MainActor
    struct View: SwiftUI.View {
        public typealias Store = ComposableArchitecture.Store<State, Action>
        private let store: Store

        public init(store: Store) {
            self.store = store
        }
    }
}

public extension ConnectedDApps.View {
	var body: some View {
		ForceFullScreen {
			WithViewStore(
				store,
				observe: ViewState.init(state:),
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
					.padding([.horizontal, .top], .medium3)
					
					Separator()

					Text("ConnectedDApps")
					
					Spacer()
				}
			}
		}
	}
}

// MARK: - ConnectedDApps.View.ViewState
extension ConnectedDApps.View {
    // MARK: ViewState
    struct ViewState: Equatable {
        init(state: ConnectedDApps.State) {
            
        }
    }
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

//struct ConnectedDApps_Preview: PreviewProvider {
//    static var previews: some View {
//        ConnectedDApps.View(
//            store: .init(
//                initialState: .init(
//                    fungibleTokenList: .init(sections: []),
//                    nonFungibleTokenList: .init(rows: [])
//                ),
//                reducer: AssetsView()
//            )
//        )
//    }
//}
#endif
