import FeaturePrelude

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
				observe: { $0 },
				send: { .view($0) }
			) { viewStore in
				ForceFullScreen {
					VStack {
						if viewStore.biometricsCheckFailed {
							Spacer()
							Image(systemName: "lock.circle.fill")
								.resizable()
								.frame(.small)
							Text("Tap anywhere to unlock")
								.textStyle(.body1HighImportance)
						}
					}
					.padding([.bottom], .medium1)
					.foregroundColor(.app.white)
					.frame(
						minWidth: 0,
						maxWidth: .infinity,
						minHeight: 0,
						maxHeight: .infinity
					)
					.background(
						Image(asset: AssetResource.splash)
							.resizable()
							.scaledToFill()
					)
					.onTapGesture {
						viewStore.send(.didTapToUnlock)
					}
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
			store: .init(initialState: .previewValue) {
				Splash()
					.dependency(\.continuousClock, ImmediateClock())
			}
		)
	}
}

extension Splash.State {
	public static let previewValue = Self()
}
#endif
