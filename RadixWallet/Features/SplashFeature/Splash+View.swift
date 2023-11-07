import ComposableArchitecture
import SwiftUI

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
							Text("Tap anywhere to unlock") // FIXME: Strings
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
				.destinations(with: store)
				.onAppear {
					viewStore.send(.appeared)
				}
			}
		}
	}
}

private extension StoreOf<Splash> {
	var destination: PresentationStoreOf<Splash.Destination> {
		scope(state: \.$destination) { .child(.destination($0)) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<Splash>) -> some View {
		let destinationStore = store.destination
		return passcodeCheckFailed(with: destinationStore)
	}

	private func passcodeCheckFailed(with destinationStore: PresentationStoreOf<Splash.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /Splash.Destination.State.passcodeCheckFailed,
			action: Splash.Destination.Action.passcodeCheckFailed
		)
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI
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
