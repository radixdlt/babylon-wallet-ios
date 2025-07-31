// MARK: - FactorSourceAccess
@Reducer
struct FactorSourceAccess: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let id: FactorSourceId
		let purpose: Purpose
		var factorSource: FactorSource?

		@Presents
		var destination: Destination.State? = nil

		var password: PasswordFactorSourceAccess.State?
		var offDeviceMnemonic: OffDeviceMnemonicFactorSourceAccess.State?
		var arculus: ArculusFactorSourceAccess.State?

		var kind: FactorSourceKind {
			id.kind
		}

		init(id: FactorSourceIdFromHash, purpose: Purpose) {
			self.id = id.asGeneral
			self.purpose = purpose
		}

		init(factorSource: FactorSource, purpose: Purpose) {
			self.id = factorSource.id
			self.factorSource = factorSource
			self.purpose = purpose
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Hashable {
		case onFirstTask
		case retryButtonTapped
		case skipButtonTapped
		case closeButtonTapped
	}

	enum InternalAction: Sendable, Hashable {
		case setFactorSource(FactorSource?)
		case hasP2PLinks(Bool)
	}

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case password(PasswordFactorSourceAccess.Action)
		case offDeviceMnemonic(OffDeviceMnemonicFactorSourceAccess.Action)
		case arculus(ArculusFactorSourceAccess.Action)
	}

	enum DelegateAction: Sendable, Hashable {
		case perform(PrivateFactorSource)
		case cancel
		case skip
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
			.ifLet(\.password, action: \.child.password) {
				PasswordFactorSourceAccess()
			}
			.ifLet(\.offDeviceMnemonic, action: \.child.offDeviceMnemonic) {
				OffDeviceMnemonicFactorSourceAccess()
			}
			.ifLet(\.arculus, action: \.child.arculus) {
				ArculusFactorSourceAccess()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			return fetchFactorSource(state: state)
				.merge(with: checkP2PLinksEffect(state: state))

		case .retryButtonTapped:
			guard let privateFactorSource = state.factorSource?.asPrivate else {
				return .none
			}
			return .send(.delegate(.perform(privateFactorSource)))

		case .skipButtonTapped:
			return .send(.delegate(.skip))

		case .closeButtonTapped:
			return .send(.delegate(.cancel))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setFactorSource(factorSource):
			guard let factorSource else {
				assertionFailure("No Factor Source found on Profile for id: \(String(describing: state.id))")
				return .send(.delegate(.cancel))
			}
			state.factorSource = factorSource
			switch factorSource {
			case let .device(value):
				return .send(.delegate(.perform(.device(value))))

			case let .ledger(value):
				return .send(.delegate(.perform(.ledger(value))))

			case let .arculusCard(value):
				if state.purpose == .signature {
					state.arculus = .init(factorSource: value)
					return .none
				}
				// Only signature requires user to provide a signature
				return .send(.delegate(.perform(.arculusCard(value, ""))))

			case let .password(value):
				state.password = .init(factorSource: value)
				return .none

			case let .offDeviceMnemonic(value):
				state.offDeviceMnemonic = .init(factorSource: value)
				return .none
			}

		case let .hasP2PLinks(hasP2PLinks):
			if !hasP2PLinks {
				state.destination = .errorAlert(.noP2Plink)
			}
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .arculus(.delegate(.perform(factorSource))):
			.send(.delegate(.perform(factorSource)))
		default:
			.none
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
		if let factorSource = state.factorSource {
			// FactorSource was provided on init, no need to fetch it
			.send(.internal(.setFactorSource(factorSource)))
		} else {
			// Fetch FactorSource from its id
			.run { [id = state.id] send in
				let factorSource = try await factorSourcesClient.getFactorSource(id: id)
				await send(.internal(.setFactorSource(factorSource)))
			}
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

private extension FactorSource {
	var asPrivate: PrivateFactorSource? {
		switch self {
		case let .device(value):
			.device(value)
		case let .ledger(value):
			.ledger(value)
		case let .arculusCard(value):
			nil
		case .offDeviceMnemonic, .password:
			nil // User needs to manually input it
		}
	}
}
