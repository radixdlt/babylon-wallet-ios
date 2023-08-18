import FeaturePrelude

extension ImportMnemonicsFlowCoordinator.State {
	var viewState: ImportMnemonicsFlowCoordinator.ViewState {
		.init()
	}
}

// MARK: - ImportMnemonicsFlowCoordinator.View
extension ImportMnemonicsFlowCoordinator {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportMnemonicsFlowCoordinator>

		public init(store: StoreOf<ImportMnemonicsFlowCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: ImportMnemonicsFlowCoordinator")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

/*
 .sheet(
     store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
     state: /SelectBackup.Destinations.State.importMnemonic,
     action: SelectBackup.Destinations.Action.importMnemonic,
     content: { store in
         NavigationView {
             ImportMnemonic.View(store: store)
                 .navigationTitle(L10n.ImportMnemonic.navigationTitle)
         }
     }
 )
 */
