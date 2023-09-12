import FeaturePrelude

extension PreviewOfSomeFeatureReducer {
	public struct View: SwiftUI.View {
		private let store: StoreOf<F>
		public init(store: StoreOf<F>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationView {
				SwitchStore(store) { state in
					switch state {
					case .previewOf:
						CaseLet(
							/F.State.previewOf,
							action: { F.Action.child(.previewOf($0)) },
							then: { Feature.View(store: $0) }
						)

					case .previewResult:
						CaseLet(
							/F.State.previewResult,
							action: { F.Action.child(.previewResult($0)) },
							then: { PreviewResult<Feature.ResultFromFeature>.View(store: $0) }
						)
					}
				}
			}
		}
	}
}
