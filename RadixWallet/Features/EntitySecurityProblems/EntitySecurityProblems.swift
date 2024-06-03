// MARK: - EntitySecurityProblems
public struct EntitySecurityProblems: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Kind: Sendable, Hashable {
			case account(AccountAddress)
			case persona(IdentityAddress)
		}

		let kind: Kind
		var problems: [SecurityProblem] = []

		public init(kind: Kind) {
			self.kind = kind
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case rowTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case setSecurityProblems([SecurityProblem])
	}

	public enum DelegateAction: Sendable, Equatable {
		case openSecurityCenter
	}

	@Dependency(\.securityCenterClient) var securityCenterClient

	public init() {}

	public func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			securityProblemsEffect()
		case .rowTapped:
			.send(.delegate(.openSecurityCenter))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setSecurityProblems(problems):
			state.problems = problems.filter(kind: state.kind)
			return .none
		}
	}
}

private extension EntitySecurityProblems {
	func securityProblemsEffect() -> Effect<Action> {
		.run { send in
			for try await problems in await securityCenterClient.problems() {
				guard !Task.isCancelled else { return }
				await send(.internal(.setSecurityProblems(problems)))
			}
		}
	}
}

private extension [SecurityProblem] {
	func filter(kind: EntitySecurityProblems.State.Kind) -> Self {
		filter {
			switch $0 {
			case .problem5, .problem6, .problem7:
				true
			case let .problem3(addresses), let .problem9(addresses):
				switch kind {
				case let .account(address):
					addresses.accounts.contains(address) || addresses.hiddenAccounts.contains(address)
				case let .persona(address):
					addresses.personas.contains(address) || addresses.hiddenPersonas.contains(address)
				}
			}
		}
	}
}
