// MARK: - Authorization
/// A modal dialog that requests user authorization -by providing biometrics- before proceeding to perform an operation (e.g. Create Account).
@Reducer
struct Authorization: FeatureReducer {
	@ObservableState
	struct State: Hashable {
		var factorSourceAccess: FactorSourceAccess.State

		init?(purpose: AuthorizationPurpose) {
			fatalError("Not implemented")
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ChildAction: Hashable {
		case factorSourceAccess(FactorSourceAccess.Action)
	}

	enum DelegateAction: Equatable {
		case authorized
		case cancelled
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess) {
			FactorSourceAccess()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .factorSourceAccess(.delegate(.perform(factorSource))):
			authorize(factorSource: factorSource)
		case .factorSourceAccess(.delegate(.cancel)):
			.send(.delegate(.cancelled))
		default:
			.none
		}
	}

	func authorize(factorSource: PrivateFactorSource) -> Effect<Action> {
		guard case .device = factorSource else {
			assertionFailure("Authorization should always take place with DeviceFactorSource")
			return .none
		}
		return .send(.delegate(.authorized))
	}
}

private extension AuthorizationPurpose {
	var factorSourceAccessPurpose: FactorSourceAccess.State.Purpose {
		switch self {
		case .creatingAccount, .creatingAccounts:
			.createAccountAuthorization
		case .creatingPersona, .creatingPersonas:
			.createPersonaAuthorization
		}
	}
}
