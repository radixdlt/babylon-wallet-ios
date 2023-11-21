// MARK: - AccountRecoveryScanInProgress
public struct AccountRecoveryScanInProgress: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let factorSourceID: FactorSourceID
		public var factorSource: Loadable<FactorSource> = .loading
		public let networkID: NetworkID
		public var offset: Int
		public let scheme: DerivationScheme
		public var active: IdentifiedArrayOf<Profile.Network.Account> = []
		public var inactive: IdentifiedArrayOf<Profile.Network.Account> = []

		@PresentationState
		public var destination: Destination.State?

		public init(factorSourceID: FactorSourceID, offset: Int, scheme: DerivationScheme, networkID: NetworkID) {
			self.offset = offset
			self.factorSourceID = factorSourceID
			self.scheme = scheme
			self.networkID = networkID
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case loadFactorSourceResult(TaskResult<FactorSource?>)
	}

	public enum ViewAction: Sendable, Equatable {
		case appear
		case scanMore
		case continueTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case foundAccounts(
			active: IdentifiedArrayOf<Profile.Network.Account>,
			inactive: IdentifiedArrayOf<Profile.Network.Account>
		)
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case derivePublicKeys(DerivePublicKeys.State)
		}

		public enum Action: Sendable, Equatable {
			case derivePublicKeys(DerivePublicKeys.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.derivePublicKeys, action: /Action.derivePublicKeys) {
				DerivePublicKeys()
			}
		}
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadFactorSourceResult(.failure(error)):
			fatalError("error handling")
		case let .loadFactorSourceResult(.success(factorSource)):
			guard let factorSource else {
				fatalError("error handling")
			}
			state.factorSource = .success(factorSource)
			return derivePublicKeys(state: &state)
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appear:
			return .run { [id = state.factorSourceID] send in
				let result = await TaskResult<FactorSource?> {
					try await factorSourcesClient.getFactorSource(id: id)
				}
				await send(.internal(.loadFactorSourceResult(result)))
			}

		case .scanMore:
			state.offset += accRecScanBatchSize
			return derivePublicKeys(state: &state)

		case .continueTapped:
			return .send(.delegate(.foundAccounts(active: state.active, inactive: state.inactive)))
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .derivePublicKeys(.delegate(.derivedPublicKeys(keys, factorSourceID, networkID))):
			assert(factorSourceID == state.factorSourceID)
			guard let factorSource = state.factorSource.wrappedValue else { fatalError("discrepancy") }
			let accounts = keys.map { hdPubKey in
				let index = hdPubKey.derivationPath.index
				let account = try! Profile.Network.Account(
					networkID: networkID,
					index: index,
					factorInstance: .init(
						factorInstance: .init(
							factorSourceID: factorSourceID,
							badge: .virtual(
								.hierarchicalDeterministic(
									hdPubKey
								)
							)
						)
					),
					displayName: "Unnamed",
					extraProperties: .init(
						appearanceID: .fromIndex(
							.init(index)
						)
					)
				)
				return account
			}.asIdentifiable()
			return scanOnLedger(accounts: accounts, state: &state)

		case .derivePublicKeys(.delegate(.failedToDerivePublicKey)):
			fatalError("error handling")
		default: return .none
		}
	}

	private func scanOnLedger(accounts: IdentifiedArrayOf<Profile.Network.Account>, state: inout State) -> Effect<Action> {
		.none
	}

	private func derivePublicKeys(
		state: inout State
	) -> Effect<Action> {
		guard let factorSource = state.factorSource.wrappedValue else { fatalError("discrepancy") }
		let offset = state.offset
		let networkID = state.networkID
		let indexRange = (offset ..< (offset + accRecScanBatchSize))
		let derivationPaths: [DerivationPath] = indexRange.map(HD.Path.Component.Child.Value.init).map {
			switch state.scheme {
			case .bip44:
				try! LegacyOlympiaBIP44LikeDerivationPath(
					index: $0
				).wrapAsDerivationPath()
			case .slip10:
				try! AccountBabylonDerivationPath(
					networkID: networkID,
					index: $0,
					keyKind: .virtualEntity
				).wrapAsDerivationPath()
			}
		}
		state.destination = .derivePublicKeys(
			.init(
				derivationPathOption: .knownPaths(
					derivationPaths,
					networkID: networkID
				),
				factorSourceOption: .specific(
					factorSource
				),
				purpose: .createEntity(kind: .account)
			)
		)
		return .none
	}
}

extension DerivationPath {
	var index: HD.Path.Component.Child.Value {
		try! hdFullPath().children.last!.nonHardenedValue
	}
}
