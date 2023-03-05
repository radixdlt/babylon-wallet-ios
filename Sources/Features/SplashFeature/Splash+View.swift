import FeaturePrelude

extension Splash.State {
	var viewState: Splash.ViewState {
		.init()
	}
}

// MARK: - Splash.View
extension Splash {
	public struct ViewState: Equatable {}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Splash>

		public init(store: StoreOf<Splash>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: { .view($0) }
			) { viewStore in
				ForceFullScreen {
					Image(asset: AssetResource.splash)
						.resizable()
						.scaledToFill()
				}
				.edgesIgnoringSafeArea(.all)
				.alert(
					store: store.scope(
						state: \.$passcodeCheckFailedAlert,
						action: { .view(.passcodeCheckFailedAlert($0)) }
					)
				)
				.onAppear {
					viewStore.send(.appeared)
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct SplashView_Previews: PreviewProvider {
	static var previews: some View {
		Splash.View(
			store: .init(
				initialState: .previewValue,
				reducer: Splash()
					.dependency(\.mainQueue, .immediate)
			)
		)
	}
}

extension Splash.State {
	public static let previewValue = Self()
}
#endif
