// MARK: - VerifyDapp

public struct VerifyDapp: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var autoDismissEnabled = false
		var autoDismissSelection = false
		let dAppMetadata: DappMetadata
		fileprivate var timer: Double = 0.0
		fileprivate let cancellationId = UUID()
		fileprivate let returnUrl: URL

		init(dAppMetadata: DappMetadata, returnUrl: URL) {
			self.dAppMetadata = dAppMetadata
			self.returnUrl = returnUrl
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case autoDismissEnabled(Bool)
		case closeTapped
		case continueTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case cancel
		case continueFlow(URL)
	}

	public enum InternalAction: Sendable, Equatable {
		case timerTick
	}

	@Dependency(\.continuousClock) var continuousClock
	var userDefaults = UserDefaults.Dependency.radix

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			state.autoDismissEnabled = userDefaults.getDappLinkingAutoContinueEnabled()
			state.timer = userDefaults.getDappLinkingDelay()
			return startTimer(state: state)

		case let .autoDismissEnabled(value):
			state.autoDismissSelection = value
			return .none

		case .closeTapped:
			return stopTimer(state: state)
				.concatenate(with: .send(.delegate(.cancel)))

		case .continueTapped:
			userDefaults.setDappLinkingAutoContinueEnabled(state.autoDismissSelection)
			return stopTimer(state: state)
				.concatenate(with: continueFlow(state: state))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .timerTick:
			state.timer -= 0.1
			if state.timer < 0 {
				return stopTimer(state: state)
					.concatenate(with: continueFlow(state: state))
			}
			return .none
		}
	}

	private func startTimer(state: State) -> Effect<Action> {
		guard state.autoDismissEnabled else {
			return .none
		}

		return .run { send in
			for await _ in continuousClock.timer(interval: .milliseconds(100)) {
				await send(.internal(.timerTick))
			}
		}
		.cancellable(id: state.cancellationId, cancelInFlight: true)
	}

	private func stopTimer(state: State) -> Effect<Action> {
		.cancel(id: state.cancellationId)
	}

	private func continueFlow(state: State) -> Effect<Action> {
		.send(.delegate(.continueFlow(state.returnUrl)))
	}
}
