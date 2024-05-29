// MARK: - EntitySecurity
public struct EntitySecurity: Sendable, FeatureReducer {
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
		case onFirstTask
		case rowTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case setSecurityProblems([SecurityProblem])
	}

	@Dependency(\.securityCenterClient) var securityCenterClient

	public init() {}

	public func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			securityProblemsEffect()
		case .rowTapped:
			.none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setSecurityProblems(problems):
			state.problems = filterProblems(problems, kind: state.kind)
			return .none
		}
	}
}

private extension EntitySecurity {
	func securityProblemsEffect() -> Effect<Action> {
		.run { send in
			for try await problems in await securityCenterClient.problems() {
				guard !Task.isCancelled else { return }
				await send(.internal(.setSecurityProblems(problems)))
			}
		}
	}

	func filterProblems(_ problems: [SecurityProblem], kind: State.Kind) -> [SecurityProblem] {
		problems.filter {
			switch $0 {
			case .problem5, .problem6, .problem7:
				true
			case let .problem3(accounts, personas), let .problem9(accounts, personas):
				switch kind {
				case let .account(address):
					accounts.contains(address)
				case let .persona(address):
					personas.contains(address)
				}
			}
		}
	}
}
