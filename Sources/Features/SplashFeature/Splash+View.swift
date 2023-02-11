import FeaturePrelude

// MARK: - Splash.View
extension Splash {
	@MainActor
	public struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension Splash.View {
	public var body: some View {
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
			.alert(store.scope(state: \.biometricsCheckFailedAlert, action: { .view(.biometricsCheckFailed($0)) }), dismiss: .dismissed)
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
import SwiftUI // NB: necessary for previews to appear

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
#endif
