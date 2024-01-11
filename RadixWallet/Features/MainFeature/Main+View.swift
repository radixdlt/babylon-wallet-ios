import ComposableArchitecture
import SwiftUI

extension Main.State {
	public var showIsUsingTestnetBanner: Bool {
		!isOnMainnet
	}
}

// MARK: - Main.View
extension Main {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Main>

		public init(store: StoreOf<Main>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStack {
				Home.View(store: store.home)
					.destinations(with: store)
			}
			.task { @MainActor in
				await store.send(.view(.task)).finish()
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
		scope(state: \.home) { .child(.home($0)) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<Main>) -> some View {
		let destinationStore = store.destination
		return navigationDestination(
			store: destinationStore,
			state: /Main.Destination.State.settings,
			action: Main.Destination.Action.settings,
			destination: { Settings.View(store: $0) }
		)
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
	public static let previewValue = Self(home: .previewValue)
}
#endif
