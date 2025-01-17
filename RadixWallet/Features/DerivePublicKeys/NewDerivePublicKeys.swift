// MARK: - NewDerivePublicKeys
@Reducer
struct NewDerivePublicKeys: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let input: KeyDerivationRequestPerFactorSource
		var factorSourceAccess: NewFactorSourceAccess.State?

		init(input: KeyDerivationRequestPerFactorSource, purpose: DerivationPurpose) {
			self.input = input
			self.factorSourceAccess = .init(id: input.factorSourceId, purpose: purpose.factorSourceAccessPurpose)
		}
	}

	typealias Action = FeatureAction<Self>

	enum InternalAction: Sendable, Hashable {
		case deriveWithSpecificPrivateHD__MustImplement
	}

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case factorSourceAccess(NewFactorSourceAccess.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case cancelled
		case finished([HierarchicalDeterministicFactorInstance])
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.factorSourceAccess, action: \.child.factorSourceAccess) {
				NewFactorSourceAccess()
			}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .factorSourceAccess(.delegate(.perform(factorSource))):
			derivePublicKeys(factorSource: factorSource, input: state.input)
		case .factorSourceAccess(.delegate(.cancel)):
			.send(.delegate(.cancelled))
		default:
			.none
		}
	}
}

private extension NewDerivePublicKeys {
	func derivePublicKeys(factorSource: FactorSource, input: KeyDerivationRequestPerFactorSource) -> Effect<Action> {
		.run { send in
			switch factorSource.kind {
			case .device:
				let factorInstances = try await deviceFactorSourceClient.getHDFactorInstances(input)
				await send(.delegate(.finished(factorInstances)))

			default:
				fatalError("Not implemented")
			}
		}
	}
}

private extension DerivationPurpose {
	var factorSourceAccessPurpose: NewFactorSourceAccess.State.Purpose {
		switch self {
		case .creatingNewAccount:
			.createAccount
		case .creatingNewPersona:
			.createPersona
		case .securifyingAccount, .securifyingPersona, .securifyingAccountsAndPersonas, .preDerivingKeys:
			fatalError("Not yet supported")
		}
	}
}
