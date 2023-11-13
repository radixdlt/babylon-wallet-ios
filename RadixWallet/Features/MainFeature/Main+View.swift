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
			}
			.task { @MainActor in
				await store.send(.view(.task)).finish()
			}
			.showDeveloperDisclaimerBanner(store.banner)
			.presentsDappInteractions()
			.destinations(with: store)
		}
	}
}

private extension StoreOf<Main> {
	var destination: PresentationStoreOf<Main.Destination_> {
		scope(state: \.$destination) { .destination($0) }
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
			store: store.destination,
			state: /Main.Destination_.State.settings,
			action: Main.Destination_.Action.settings,
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
