import ComposableArchitecture
import SwiftUI

// MARK: - OnboardingCoordinator.View
extension OnboardingCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<OnboardingCoordinator>

		init(store: StoreOf<OnboardingCoordinator>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			OnboardingStartup.View(store: store.startup)
				.destinations(with: store)
		}
	}
}

private extension StoreOf<OnboardingCoordinator> {
	var destination: PresentationStoreOf<OnboardingCoordinator.Destination> {
		func scopeState(state: State) -> PresentationState<OnboardingCoordinator.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}

	var startup: StoreOf<OnboardingStartup> {
		scope(state: \.startup, action: \.child.startup)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<OnboardingCoordinator>) -> some View {
		let destinationStore = store.destination
		return createAccount(with: destinationStore)
	}

	private func createAccount(with destinationStore: PresentationStoreOf<OnboardingCoordinator.Destination>) -> some View {
		fullScreenCover(store: destinationStore.scope(state: \.createAccount, action: \.createAccount)) {
			CreateAccountCoordinator.View(store: $0)
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

struct Onboarding_Preview: PreviewProvider {
	static var previews: some View {
		OnboardingCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: OnboardingCoordinator.init
			)
		)
	}
}

extension OnboardingCoordinator.State {
	static let previewValue: Self = {
		fatalError("impl me")
	}()
}
#endif
