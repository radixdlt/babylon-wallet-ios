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

		public var mode: Mode
		public var status: Status
		public var networkID: NetworkID = .mainnet
		public var batchNumber: Int = 0
		public var maxIndex: HDPathValue? = nil

		public var indicesOfAlreadyUsedEntities: OrderedSet<HDPathValue> = []
		public let forOlympiaAccounts: Bool
		public var active: IdentifiedArrayOf<Sargon.Account> = []
		public var inactive: IdentifiedArrayOf<Sargon.Account> = []

		@PresentationState
		public var destination: Destination.State? = nil

		public enum Mode: Sendable, Hashable {
			case privateHD(PrivateHDFactorSource)
			case factorSourceWithID(id: FactorSourceIDFromHash, Loadable<FactorSource> = .idle)
		}

		public var factorSourceIDFromHash: FactorSourceIDFromHash {
			switch mode {
			case let .privateHD(privateHD):
				privateHD.factorSource.id
			case let .factorSourceWithID(id, _):
				id
			}
		}

		public init(
			mode: Mode,
			forOlympiaAccounts: Bool = false,
			status: Status = .new
		) {
			self.mode = mode
			self.forOlympiaAccounts = forOlympiaAccounts
			self.status = status
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case loadIndicesUsedByFactorSourceResult(TaskResult<IndicesUsedByFactorSource>)
		case startScan(accounts: IdentifiedArrayOf<Sargon.Account>)
		case foundAccounts(
			active: IdentifiedArrayOf<Sargon.Account>,
			inactive: IdentifiedArrayOf<Sargon.Account>
		)
		case initiate
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstAppear
		case scanMore
		case continueTapped
		case closeButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case foundAccounts(
			active: IdentifiedArrayOf<Sargon.Account>,
			inactive: IdentifiedArrayOf<Sargon.Account>
		)
		case failed
		case close
	}

	// MARK: - Destination
	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Hashable, Sendable {
			case derivePublicKeys(DerivePublicKeys.State)
		}

		@CasePathable
		public enum Action: Equatable, Sendable {
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

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .initiate:
			switch state.mode {
			case .privateHD:
				return derivePublicKeys(state: &state)
			case .factorSourceWithID:
				state.status = .loadingFactorSource
				let id = state.factorSourceIDFromHash
				state.mode = .factorSourceWithID(id: id, .loading)
				return .run { [forOlympiaAccounts = state.forOlympiaAccounts] send in
					let result = await TaskResult<IndicesUsedByFactorSource> {
						try await factorSourcesClient.indicesOfEntitiesControlledByFactorSource(
							.init(
								entityKind: .account,
								factorSourceID: id.embed(),
								derivationPathScheme: forOlympiaAccounts ? .bip44Olympia : .cap26,
								networkID: nil // read current, then we will update `state.networkID` with current.
							)
						)
					}
					await send(.internal(.loadIndicesUsedByFactorSourceResult(result)))
				}
			}

		case let .loadIndicesUsedByFactorSourceResult(.failure(error)):
			let errorMsg = "Failed to load indices used by factor source, error: \(error)"
			loggerGlobal.error(.init(stringLiteral: errorMsg))
			return .send(.delegate(.failed))

		case let .loadIndicesUsedByFactorSourceResult(.success(indicesUsedByFactorSource)):
			let networkID = indicesUsedByFactorSource.currentNetworkID
			if state.networkID != networkID {
				loggerGlobal.notice("Updating networkID to: \(networkID)")
				state.networkID = networkID
			}

			state.mode = .factorSourceWithID(
				id: state.factorSourceIDFromHash,
				.success(
					indicesUsedByFactorSource.factorSource
				)
			)

			state.indicesOfAlreadyUsedEntities = indicesUsedByFactorSource.indices
			return derivePublicKeys(state: &state)

		case let .startScan(accounts):
			return scanOnLedger(accounts: accounts, state: &state)

		case let .foundAccounts(active, inactive):
			state.batchNumber += 1
			state.status = .scanComplete
			state.active.append(contentsOf: active)
			state.inactive.append(contentsOf: inactive)
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstAppear:
			guard state.status == .new else {
				return .none
			}

			/// A temporary hack to fix ABW-2657. When the deriving public keys slide up will not show
			return delayedShortEffect(for: .internal(.initiate))

		case .scanMore:
			loggerGlobal.debug("Scan more requested.")
			return derivePublicKeys(state: &state)

		case .continueTapped:
			if let maxActive = state.active.max() {
				let inactiveInBetweenActive = state.inactive.filter {
					$0.derivationIndex < maxActive.derivationIndex
				}
				return .send(.delegate(.foundAccounts(active: state.active, inactive: inactiveInBetweenActive)))
			} else {
				return .send(.delegate(.foundAccounts(active: [], inactive: [])))
			}

		case .closeButtonTapped:
			return .send(.delegate(.close))
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		let globalOffset = state.active.count + state.inactive.count
		switch presentedAction {
		case let .derivePublicKeys(.delegate(delegateAction)):
			switch delegateAction {
			case let .derivedPublicKeys(publicHDKeys, factorSourceID, networkID):
				let id = state.factorSourceIDFromHash
				assert(factorSourceID == id.embed())
				assert(networkID == state.networkID)
				loggerGlobal.debug("Creating accounts with networkID: \(networkID)")
				return .run { send in
					let accounts = try await publicHDKeys.enumerated().asyncMap { localOffset, publicHDKey in
						let offset = localOffset + globalOffset
						let appearanceID = await accountsClient.nextAppearanceID(networkID, offset)
						return try Sargon.Account(
							networkID: networkID,
							factorInstance: HierarchicalDeterministicFactorInstance(
								factorSourceID: id,
								publicHDKey: publicHDKey
							),
							displayName: .init(rawValue: L10n.AccountRecoveryScan.InProgress.nameOfRecoveredAccount) ?? "Unnamed",
							extraProperties: .init(
								appearanceID: appearanceID,
								// We will be replacing the `depositRule` with one fetched from GW
								// in `scan` step later on.
								onLedgerSettings: .unknown
							)
						)
					}.asIdentified()

					await send(.internal(.startScan(accounts: accounts)))
				} catch: { error, send in
					let errorMsg = "Failed to create account, error: \(error)"
					loggerGlobal.critical(.init(stringLiteral: errorMsg))
					assertionFailure(errorMsg)
					await send(.delegate(.failed))
				}

			case .failedToDerivePublicKey:
				return .send(.delegate(.failed))

			case .cancel:
				return .send(.delegate(.close))
			}

		default: return .none
		}
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		.run { _ in await dismiss() }
	}
}

extension AccountRecoveryScanInProgress {
	private func nextDerivationPaths(state: inout State) throws -> OrderedSet<DerivationPath> {
		let networkID = state.networkID

		let derivationIndices = generateIntegers(
			start: state.maxIndex ?? 0,
			count: batchSize,
			excluding: state.indicesOfAlreadyUsedEntities
		)
		assert(derivationIndices.count == batchSize)
		state.maxIndex = derivationIndices.max()! + 1

		let paths = try derivationIndices.map { index in
			if state.forOlympiaAccounts {
				try Bip44LikePath(
					index: index
				)
				.wrapAsDerivationPath()
			} else {
				try AccountBabylonDerivationPath(
					networkID: networkID,
					index: index,
					keyKind: .virtualEntity
				)
				.wrapAsDerivationPath()
			}
		}

		return try OrderedSet(validating: paths)
	}

	private func derivePublicKeys(
		state: inout State
	) -> Effect<Action> {
		let derivationPaths: OrderedSet<DerivationPath>
		do {
			derivationPaths = try nextDerivationPaths(state: &state)
		} catch {
			let errorMsg = "Failed to calculate next derivation paths"
			loggerGlobal.error(.init(stringLiteral: errorMsg))
			assertionFailure(errorMsg)
			return .send(.delegate(.failed))
		}
		let factorSourceOption: DerivePublicKeys.State.FactorSourceOption
		switch state.mode {
		case let .factorSourceWithID(_, loadableState):
			switch loadableState {
			case let .success(factorSource):
				factorSourceOption = .specific(factorSource)
			default:
				let errorMsg = "Discrepancy! Expected to loaded the factor source"
				loggerGlobal.error(.init(stringLiteral: errorMsg))
				assertionFailure(errorMsg)
				return .send(.delegate(.failed))
			}
		case let .privateHD(privateHDFactorSource):
			factorSourceOption = .specificPrivateHDFactorSource(privateHDFactorSource)
		}

		state.status = .derivingPublicKeys
		state.destination = .derivePublicKeys(.init(
			derivationPathOption: .knownPaths(
				Array(derivationPaths),
				networkID: state.networkID
			),
			factorSourceOption: factorSourceOption,
			purpose: .accountRecoveryScan
		))

		return .none
	}

	private func scanOnLedger(
		accounts: IdentifiedArrayOf<Sargon.Account>,
		state: inout State
	) -> Effect<Action> {
		assert(accounts.count == batchSize)
		state.status = .scanningNetworkForActiveAccounts
		state.destination = nil
		loggerGlobal.debug("Scanning ledger with accounts with addresses: \(accounts.map(\.address))")
		return .run { send in

			let onLedgerSyncOfAccounts = try await onLedgerEntitiesClient
				.syncThirdPartyDepositWithOnLedgerSettings(
					addressesOf: accounts
				)

			await send(
				.internal(
					.foundAccounts(
						active: onLedgerSyncOfAccounts.active,
						inactive: onLedgerSyncOfAccounts.inactive
					)
				)
			)
		} catch: { error, send in
			loggerGlobal.error("Failed to scan network, error: \(error)")
			await send(.delegate(.failed))
		}
	}
}

extension DerivationPath {
	var index: HDPathValue {
		do {
			guard let index = try hdFullPath().children.last?.nonHardenedValue else {
				fatalError("Expected to ALWAYS be able to read the last path component of an HD paths' index, but was nil.")
			}
			return index
		} catch {
			fatalError("Expected to ALWAYS be able to read the last path component of an HD paths' index, got error: \(error)")
		}
	}
}
