import SwiftUI

// MARK: - SelectFactorSourcesCoordinator.View
extension SelectFactorSourcesCoordinator {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<SelectFactorSourcesCoordinator>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				Group {
					switch store.path.case {
					case let .selectFactorSources(store):
						SelectFactorSources.View(store: store)
					}
				}
			}
		}
	}
}

private extension StoreOf<SelectFactorSourcesCoordinator> {
	var path: StoreOf<SelectFactorSourcesCoordinator.Path> {
		scope(state: \.path, action: \.child.path)
	}
}
