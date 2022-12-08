import ComposableArchitecture
import DesignSystem
import Resources
import SwiftUI

// MARK: - Splash.View
public extension Splash {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension Splash.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				Image(asset: AssetResource.splash)
					.resizable()
					.scaledToFill()
			}
			.edgesIgnoringSafeArea(.all)
			.alert(store.scope(state: \.alert, action: { .view($0) }), dismiss: .alertRetryButtonTapped)
			.onAppear {
				viewStore.send(.viewAppeared)
			}
		}
	}
}

// MARK: - Splash.View.ViewState
extension Splash.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Splash.State) {}
	}
}

#if DEBUG

// MARK: - SplashView_Previews
struct SplashView_Previews: PreviewProvider {
	static var previews: some View {
		Splash.View(
			store: .init(
				initialState: .init(),
				reducer: Splash()
					.dependency(\.mainQueue, .immediate)
			)
		)
	}
}
#endif // DEBUG
