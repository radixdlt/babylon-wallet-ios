import ComposableArchitecture
import SwiftUI

// MARK: - Splash.View
extension Splash {
	struct ViewState: Equatable {}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Splash>

		init(store: StoreOf<Splash>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: { $0 },
				send: { .view($0) }
			) { viewStore in
				SplashView(biometricsCheckFailed: viewStore.biometricsCheckFailed)
					.onTapGesture {
						viewStore.send(.didTapToUnlock)
					}
					.edgesIgnoringSafeArea(.all)
					.destinations(with: store)
					.task {
						viewStore.send(.appeared)
					}
			}
		}
	}
}

private extension StoreOf<Splash> {
	var destination: PresentationStoreOf<Splash.Destination> {
		func scopeState(state: State) -> PresentationState<Splash.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<Splash>) -> some View {
		let destinationStore = store.destination
		return errorAlert(with: destinationStore)
	}

	private func errorAlert(with destinationStore: PresentationStoreOf<Splash.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.errorAlert, action: \.errorAlert))
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
	static let previewValue = Self()
}
#endif

// MARK: - SplashView
struct SplashView: View {
	var biometricsCheckFailed: Bool = false

	var body: some View {
		VStack {
			if biometricsCheckFailed {
				Spacer()
				Image(systemName: "lock.circle.fill")
					.resizable()
					.frame(.small)
				Text(L10n.Splash.tapAnywhereToUnlock)
					.textStyle(.body1HighImportance)
			}
		}
		.padding(.bottom, .medium1)
		.foregroundColor(.app.white)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(
			Image(.splash)
				.resizable()
				.scaledToFill()
		)
		.edgesIgnoringSafeArea(.all)
	}
}
