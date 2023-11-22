// MARK: - AccountRecoveryScanInProgress
public struct AccountRecoveryScanInProgress: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Status: Sendable, Hashable {
			case new
			case loadingFactorSource
			case derivingPublicKeys
			case scanningNetworkForActiveAccounts
			case scanComplete
		}

		public var status: Status = .new
		public let factorSourceID: FactorSourceID.FromHash
		public var factorSource: Loadable<FactorSource>
		public let networkID: NetworkID
		public var offset: Int
		public let scheme: DerivationScheme
		public var active: IdentifiedArrayOf<Profile.Network.Account> = []
		public var inactive: IdentifiedArrayOf<Profile.Network.Account> = []

		@PresentationState
		public var destination: Destination.State? {
			didSet {
				if case .some(.derivePublicKeys) = destination {
					self.status = .derivingPublicKeys
				}
			}
		}

		public init(
			factorSourceID: FactorSourceID.FromHash,
			factorSource: Loadable<FactorSource> = .loading,
			offset: Int,
			scheme: DerivationScheme,
			networkID: NetworkID
		) {
			if let factorSource = factorSource.wrappedValue {
				assert(factorSourceID.embed() == factorSource.id)
			}
			self.offset = offset
			self.factorSourceID = factorSourceID
			self.scheme = scheme
			self.networkID = networkID
			self.factorSource = factorSource
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
			return derivePublicKeys(using: factorSource, state: &state)
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appear:
			if let factorSource = state.factorSource.wrappedValue {
				return derivePublicKeys(using: factorSource, state: &state)
			} else {
				state.status = .loadingFactorSource
				return .run { [id = state.factorSourceID] send in
					let result = await TaskResult<FactorSource?> {
						try await factorSourcesClient.getFactorSource(id: id.embed())
					}
					await send(.internal(.loadFactorSourceResult(result)))
				}
			}

		case .scanMore:
			guard let factorSource = state.factorSource.wrappedValue else { fatalError("discrepancy") }
			state.offset += accRecScanBatchSize
			return derivePublicKeys(using: factorSource, state: &state)

		case .continueTapped:
			return .send(.delegate(.foundAccounts(active: state.active, inactive: state.inactive)))
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .derivePublicKeys(.delegate(delegateAction)):
			loggerGlobal.notice("Finish deriving public keys")
			state.destination = nil
			switch delegateAction {
			case let .derivedPublicKeys(publicHDKeys, factorSourceID, networkID):
				assert(factorSourceID == state.factorSourceID.embed())
				assert(networkID == state.networkID)

				let accounts = publicHDKeys.map { publicHDKey in
					let index = publicHDKey.derivationPath.index
					let account = try! Profile.Network.Account(
						networkID: networkID,
						index: index,
						factorInstance: .init(
							factorSourceID: state.factorSourceID,
							publicHDKey: publicHDKey
						),
						displayName: "Unnamed",
						extraProperties: .init(index: index)
					)
					return account
				}.asIdentifiable()

				return scanOnLedger(accounts: accounts, state: &state)
			case .failedToDerivePublicKey:
				fatalError("failed to derive keys")
			}

		default: return .none
		}
	}

	private func scanOnLedger(accounts: IdentifiedArrayOf<Profile.Network.Account>, state: inout State) -> Effect<Action> {
		state.status = .scanningNetworkForActiveAccounts
		return .none
	}

	private func derivePublicKeys(
		using factorSource: FactorSource,
		state: inout State
	) -> Effect<Action> {
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
