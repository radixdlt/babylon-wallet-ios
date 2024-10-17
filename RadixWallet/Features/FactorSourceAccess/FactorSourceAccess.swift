// MARK: - FactorSourceAccess
struct FactorSourceAccess: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let kind: Kind
		let purpose: Purpose

		@PresentationState
		var destination: Destination.State? = nil

		init(kind: Kind, purpose: Purpose) {
			self.kind = kind
			self.purpose = purpose
		}
	}

	enum ViewAction: Sendable, Hashable {
		case onFirstTask
		case retryButtonTapped
		case closeButtonTapped
	}

	enum InternalAction: Sendable, Hashable {
		case hasP2PLinks(Bool)
	}

	enum DelegateAction: Sendable, Hashable {
		case perform
		case cancel
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case noP2PLink(AlertState<NoP2PLinkAlert>)
		}

		@CasePathable
		enum Action: Sendable, Hashable {
			case noP2PLink(NoP2PLinkAlert)
		}

		var body: some ReducerOf<Self> {
			EmptyReducer()
		}

		enum NoP2PLinkAlert: Sendable, Hashable {
			case okTapped
		}
	}

	@Dependency(\.p2pLinksClient) var p2pLinksClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	init() {}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			.send(.delegate(.perform))
				.merge(with: checkP2PLinksEffect(state: state))
		case .retryButtonTapped:
			.send(.delegate(.perform))
		case .closeButtonTapped:
			.send(.delegate(.cancel))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .hasP2PLinks(hasP2PLinks):
			if !hasP2PLinks {
				state.destination = .noP2PLink(.noP2Plink)
			}
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .noP2PLink(.okTapped):
			state.destination = nil
			return .run { send in
				// Dispatching this in an async process is enough for it to take place after alert has been dismissed.
				// No need to place an actual delay with continuousClock.
				await send(.delegate(.cancel))
			}
		}
	}

	private func checkP2PLinksEffect(state: State) -> Effect<Action> {
		guard case .ledger = state.kind else {
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

extension FactorSourceAccess.State {
	enum Kind: Sendable, Hashable {
		case device
		case ledger(LedgerHardwareWalletFactorSource?)
	}

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

private extension AlertState<FactorSourceAccess.Destination.NoP2PLinkAlert> {
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
