import ComposableArchitecture
import SwiftUI

extension CreateAccountCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<CreateAccountCoordinator>

		init(store: StoreOf<CreateAccountCoordinator>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack(path: $store.scope(state: \.path, action: \.child.path)) {
					destinations(for: store.scope(state: \.root, action: \.child.root))
						.withNavigationBar(closeAction: {
							store.send(.view(.closeButtonTapped))
						})
				} destination: { destStore in
					destinations(for: destStore)
						.navigationBarBackButtonHidden(!store.shouldDisplayNavBar)
						.navigationBarHidden(!store.shouldDisplayNavBar)
						.background(.primaryBackground)
				}
			}
		}

		private func destinations(
			for store: StoreOf<CreateAccountCoordinator.Path>
		) -> some SwiftUI.View {
			SwitchStore(store) { state in
				switch state {
				case .nameAccount:
					if let store = store.scope(state: \.nameAccount, action: \.nameAccount) {
						NameAccount.View(store: store)
					}
				case .selectFactorSource:
					if let store = store.scope(state: \.selectFactorSource, action: \.selectFactorSource) {
						SelectFactorSource.View(store: store)
					}
				case .completion:
					if let store = store.scope(state: \.completion, action: \.completion) {
						NewAccountCompletion.View(store: store)
					}
				}
			}
		}
	}
}
