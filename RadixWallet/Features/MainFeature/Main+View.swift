import ComposableArchitecture
import SwiftUI

extension Main.State {
	var showIsUsingTestnetBanner: Bool {
		!isOnMainnet
	}
}

// MARK: - Main.View
extension Main {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Main>

		init(store: StoreOf<Main>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			NavigationStack {
				Home.View(store: store.home)
					.destinations(with: store)
			}
			.task {
				store.send(.view(.task))
			}
			.showDeveloperDisclaimerBanner(store.banner)
			.presentsDappInteractions()
		}
	}
}

private extension StoreOf<Main> {
	var destination: PresentationStoreOf<Main.Destination> {
		func scopeState(state: State) -> PresentationState<Main.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}

	var banner: Store<Bool, Never> {
		scope(state: \.showIsUsingTestnetBanner, action: actionless)
	}

	var home: StoreOf<Home> {
		scope(state: \.home, action: \.child.home)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<Main>) -> some View {
		let destinationStore = store.destination
		return navigationDestination(store: destinationStore.scope(state: \.settings, action: \.settings)) {
			Settings.View(store: $0)
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

struct MainView_Previews: PreviewProvider {
	static var previews: some SwiftUI.View {
		Main.View(
			store: .init(
				initialState: .previewValue,
				reducer: Main.init
			)
		)
	}
}

extension Main.State {
	static let previewValue = Self(home: .previewValue)
}
#endif
