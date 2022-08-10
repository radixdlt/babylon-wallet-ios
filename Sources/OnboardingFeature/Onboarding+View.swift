import Common
import ComposableArchitecture
import Foundation
import Profile
import SwiftUI
import UserDefaultsClient
import Wallet

public extension Onboarding {
	struct Coordinator: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

internal extension Onboarding.Coordinator {
	// MARK: ViewState
	struct ViewState: Equatable {
		@BindableState var profileName: String
		var canProceed: Bool

		init(
			state: Onboarding.State
		) {
			profileName = state.profileName
			canProceed = state.canProceed
		}
	}
}

internal extension Onboarding.Coordinator {
	// MARK: ViewAction
	enum ViewAction: Equatable, BindableAction {
		case binding(BindingAction<ViewState>)
		case createWalletButtonPressed
	}
}

private extension Onboarding.State {
	var view: Onboarding.Coordinator.ViewState {
		get { .init(state: self) }
		set {
			// handle bindable actions only:
			profileName = newValue.profileName
			canProceed = newValue.canProceed
		}
	}
}

internal extension Onboarding.Action {
	init(action: Onboarding.Coordinator.ViewAction) {
		switch action {
		case let .binding(bindingAction):
			self = .binding(
				bindingAction.pullback(\Onboarding.State.view)
			)
		case .createWalletButtonPressed:
			self = .internal(.user(.createWallet))
		}
	}
}

public extension Onboarding.Coordinator {
	// MARK: Body
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Onboarding.Action.init
			)
		) { viewStore in
			ForceFullScreen {
				VStack {
					TextField("Profile Name", text: viewStore.binding(\.$profileName))
					Button("Create wallet") {
						viewStore.send(.createWalletButtonPressed)
					}
					.disabled(!viewStore.canProceed)
				}
			}
		}
	}
}

// MARK: - OnboardingCoordinator_Previews
#if DEBUG
struct OnboardingCoordinator_Previews: PreviewProvider {
	static var previews: some View {
		Onboarding.Coordinator(
			store: .init(
				initialState: .init(),
				reducer: Onboarding.reducer,
				environment: .init(
					backgroundQueue: .immediate,
					mainQueue: .immediate,
					userDefaultsClient: .noop
				)
			)
		)
	}
}
#endif // DEBUG
