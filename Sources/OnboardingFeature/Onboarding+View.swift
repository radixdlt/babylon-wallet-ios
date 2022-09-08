import Common
import ComposableArchitecture
import SwiftUI

public extension Onboarding {
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension Onboarding.View {
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

extension Onboarding.View {
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

extension Onboarding.View {
	// MARK: ViewAction
	enum ViewAction: Equatable, BindableAction {
		case binding(BindingAction<ViewState>)
		case createWalletButtonPressed
	}
}

extension Onboarding.Action {
	init(action: Onboarding.View.ViewAction) {
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

private extension Onboarding.State {
	var view: Onboarding.View.ViewState {
		get { .init(state: self) }
		set {
			// handle bindable actions only:
			profileName = newValue.profileName
			canProceed = newValue.canProceed
		}
	}
}

// MARK: - OnboardingView_Previews
struct OnboardingView_Previews: PreviewProvider {
	static var previews: some View {
		Onboarding.View(
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
