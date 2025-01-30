// MARK: - FactorSourceAccess
@Reducer
struct FactorSourceAccess: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let id: FactorSourceIdFromHash?
		let purpose: Purpose
		var factorSource: FactorSource?

		@Presents
		var destination: Destination.State? = nil

		var password: PasswordFactorSourceAccess.State?

		var kind: FactorSourceKind {
			id?.kind ?? .device
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
	}

	enum DelegateAction: Sendable, Hashable {
		case perform(FactorSource)
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
			case .device, .ledger, .arculusCard:
				return .send(.delegate(.perform(factorSource)))

			case let .password(value):
				state.password = .init(factorSource: value)
				return .none

			case .offDeviceMnemonic:
				fatalError("")
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
			if let id {
				let factorSource = try await factorSourcesClient.getFactorSource(id: id.asGeneral)
				await send(.internal(.setFactorSource(factorSource)))
			} else {
				// If no id is set, we need to get main BDFS
				let mainBdfs = try SargonOS.shared.mainBdfs()
				await send(.internal(.setFactorSource(mainBdfs.asGeneral)))
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
