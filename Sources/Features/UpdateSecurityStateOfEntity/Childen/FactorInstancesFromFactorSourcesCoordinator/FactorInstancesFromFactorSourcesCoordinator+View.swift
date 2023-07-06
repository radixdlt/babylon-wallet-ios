import FeaturePrelude

extension FactorInstancesFromFactorSourcesCoordinator.State {
	var viewState: FactorInstancesFromFactorSourcesCoordinator.ViewState {
		.init()
	}
}

// MARK: - FactorInstancesFromFactorSourcesCoordinator.View
extension FactorInstancesFromFactorSourcesCoordinator {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FactorInstancesFromFactorSourcesCoordinator>

		public init(store: StoreOf<FactorInstancesFromFactorSourcesCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					// TODO: implement
					Text("Implement: FactorInstancesFromFactorSourcesCoordinator")
						.background(Color.yellow)
						.foregroundColor(.red)
						.onAppear { viewStore.send(.appeared) }

					Button("Continue") {
						viewStore.send(.continue)
					}
				}
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - FactorInstancesFromFactorSources_Preview
// struct FactorInstancesFromFactorSources_Preview: PreviewProvider {
//	static var previews: some View {
//		FactorInstancesFromFactorSourcesCoordinator.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: FactorInstancesFromFactorSourcesCoordinator()
//			)
//		)
//	}
// }
//
// extension FactorInstancesFromFactorSourcesCoordinator.State {
//	public static let previewValue = Self()
// }
// #endif
