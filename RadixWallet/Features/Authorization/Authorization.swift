// MARK: - Authorization
/// A modal dialog that requests user authorization -by providing biometrics- before proceeding to perform an operation (e.g. Create Account).
@Reducer
struct Authorization: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var factorSourceAccess: FactorSourceAccess.State

		init?(purpose: AuthorizationPurpose) {
			fatalError("Not implemented")
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case factorSourceAccess(FactorSourceAccess.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case authorized
		case cancelled
	}

	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.errorQueue) var errorQueue

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
		.run { send in
			switch factorSource {
			case let .device(device):
				let _ = try secureStorageClient.loadMnemonic(factorSourceID: device.id, notifyIfMissing: false)
				await send(.delegate(.authorized))
			default:
				fatalError("Authorization should always take place with DeviceFactorSource")
			}
		} catch: { error, _ in
			if !error.isUserCanceledKeychainAccess {
				// If user cancelled the operation, we will allow them to retry.
				// In any other situation we handle the error.
				errorQueue.schedule(error)
			}
		}
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
