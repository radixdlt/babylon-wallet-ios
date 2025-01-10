import SwiftUI

// MARK: - ChooseFactorSourceCoordinator.View
extension ChooseFactorSourceCoordinator {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<ChooseFactorSourceCoordinator>
		@Environment(\.dismiss) var dismiss

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack(path: $store.scope(state: \.path, action: \.child.path)) {
					ChooseFactorSourceKind.View(store: store.kind)
				} destination: { destination in
					switch destination.case {
					case let .list(store):
						FactorSourcesList.View(store: store)
					}
				}
				.withNavigationBar {
					dismiss()
				}
			}
		}
	}
}

private extension StoreOf<ChooseFactorSourceCoordinator> {
	var kind: StoreOf<ChooseFactorSourceKind> {
		scope(state: \.kind, action: \.child.kind)
	}
}
