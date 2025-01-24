// MARK: - FactorSourceAccess
@Reducer
struct FactorSourceAccess: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let id: FactorSourceIdFromHash
		let purpose: Purpose
		var factorSource: FactorSource?

		@Presents
		var destination: Destination.State? = nil

		var kind: FactorSourceKind {
			id.kind
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Hashable {
		case onFirstTask
		case retryButtonTapped
		case closeButtonTapped
	}

	enum InternalAction: Sendable, Hashable {
		case setFactorSource(FactorSource?)
		case hasP2PLinks(Bool)
	}

	enum DelegateAction: Sendable, Hashable {
		case perform(FactorSource)
		case cancel
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case errorAlert(AlertState<ErrorAlert>)
		}

		@CasePathable
		enum Action: Sendable, Hashable {
			case errorAlert(ErrorAlert)
		}

		var body: some ReducerOf<Self> {
			EmptyReducer()
		}

		enum ErrorAlert: Sendable, Hashable {
			case okTapped
		}
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.p2pLinksClient) var p2pLinksClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			return fetchFactorSource(state: state)
				.merge(with: checkP2PLinksEffect(state: state))
		case .retryButtonTapped:
			guard let factorSource = state.factorSource else {
				return .none
			}
			return .send(.delegate(.perform(factorSource)))
		case .closeButtonTapped:
			return .send(.delegate(.cancel))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setFactorSource(factorSource):
			if let factorSource {
				state.factorSource = factorSource
				return .send(.delegate(.perform(factorSource)))
			} else {
				assertionFailure("No Factor Source found on Profile for id: \(state.id)")
				return .send(.delegate(.cancel))
			}

		case let .hasP2PLinks(hasP2PLinks):
			if !hasP2PLinks {
				state.destination = .errorAlert(.noP2Plink)
			}
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .errorAlert(.okTapped):
			state.destination = nil
			return .run { send in
				// Dispatching this in an async process is enough for it to take place after alert has been dismissed.
				// No need to place an actual delay with continuousClock.
				await send(.delegate(.cancel))
			}
		}
	}
}

private extension FactorSourceAccess {
	func fetchFactorSource(state: State) -> Effect<Action> {
		.run { [id = state.id] send in
			let factorSource = try await factorSourcesClient.getFactorSource(id: id.asGeneral)
			await send(.internal(.setFactorSource(factorSource)))
		}
	}

	func checkP2PLinksEffect(state: State) -> Effect<Action> {
		guard case .ledgerHqHardwareWallet = state.kind else {
			return .none
		}
		return .run { send in
			let result = await p2pLinksClient.hasP2PLinks()
			await send(.internal(.hasP2PLinks(result)))
		} catch: { error, _ in
			loggerGlobal.error("failed to check if has p2p links, error: \(error)")
		}
	}
}

// MARK: - FactorSourceAccess.State.Purpose
extension FactorSourceAccess.State {
	enum Purpose: Sendable, Hashable {
		/// Signing transactions.
		case signature

		/// Adding a new account.
		case createAccount

		/// Adding a new persona.
		case createPersona

		/// Recovery of existing accounts.
		case deriveAccounts

		/// ROLA proof of accounts/personas.
		case proveOwnership

		/// Encrypting messages on transactions.
		case encryptMessage

		/// MFA signing, ROLA or encryption.
		case createKey
	}
}

private extension AlertState<FactorSourceAccess.Destination.ErrorAlert> {
	static var noP2Plink: AlertState {
		AlertState {
			TextState(L10n.LedgerHardwareDevices.LinkConnectorAlert.title)
		} actions: {
			ButtonState(action: .okTapped) {
				TextState(L10n.Common.ok)
			}
		} message: {
			TextState(L10n.LedgerHardwareDevices.LinkConnectorAlert.message)
		}
	}
}
