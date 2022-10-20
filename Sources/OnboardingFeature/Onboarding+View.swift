import Common
import ComposableArchitecture
import SwiftUI

// MARK: - Onboarding.View
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
			store,
			observe: ViewState.init(state:),
			send: Onboarding.Action.init
		) { viewStore in
			ForceFullScreen {
				VStack {
					TextField("Name of first account", text: viewStore.binding(\.$nameOfFirstAccount))
					Button("Create Profle") {
						viewStore.send(.createProfileButtonPressed)
					}
					.disabled(!viewStore.canProceed)
				}
			}
		}
	}
}

// MARK: - Onboarding.View.ViewState
extension Onboarding.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		@BindableState var nameOfFirstAccount: String
		var canProceed: Bool

		init(state: Onboarding.State) {
			nameOfFirstAccount = state.nameOfFirstAccount
			canProceed = state.canProceed
		}
	}
}

// MARK: - Onboarding.View.ViewAction
extension Onboarding.View {
	// MARK: ViewAction
	enum ViewAction: Equatable, BindableAction {
		case binding(BindingAction<ViewState>)
		case createProfileButtonPressed
	}
}

extension Onboarding.Action {
	init(action: Onboarding.View.ViewAction) {
		switch action {
		case let .binding(bindingAction):
			self = .binding(
				bindingAction.pullback(\Onboarding.State.view)
			)
		case .createProfileButtonPressed:
			self = .internal(.user(.createProfile))
		}
	}
}

private extension Onboarding.State {
	var view: Onboarding.View.ViewState {
		get { .init(state: self) }
		set {
			// handle bindable actions only:
			nameOfFirstAccount = newValue.nameOfFirstAccount
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
