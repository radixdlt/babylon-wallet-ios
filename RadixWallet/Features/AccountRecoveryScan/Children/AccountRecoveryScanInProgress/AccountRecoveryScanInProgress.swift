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

		public var status: Status
		public var networkID: NetworkID = .mainnet
		public var batchNumber: Int = 0
		public var maxIndex: HD.Path.Component.Child.Value? = nil

		public var indicesOfAlreadyUsedEntities: OrderedSet<HD.Path.Component.Child.Value> = []
		public let forOlympiaAccounts: Bool
		public var active: IdentifiedArrayOf<Profile.Network.Account> = []
		public var inactive: IdentifiedArrayOf<Profile.Network.Account> = []

		@PresentationState
		public var destination: Destination.State? = nil

		public enum Mode: Sendable, Hashable {
			case privateHD(PrivateHDFactorSource)
			case factorSourceWithID(id: FactorSourceID.FromHash, Loadable<FactorSource> = .idle)
		}

		public var factorSourceIDFromHash: FactorSourceID.FromHash {
			switch mode {
			case let .privateHD(privateHD):
				privateHD.factorSource.id
			case let .factorSourceWithID(id, _):
				id
			}
		}

		public var mode: Mode

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
		case startScan(accounts: IdentifiedArrayOf<Profile.Network.Account>)
		case foundAccounts(
			active: IdentifiedArrayOf<Profile.Network.Account>,
			inactive: IdentifiedArrayOf<Profile.Network.Account>
		)
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstAppear
		case scanMore
		case continueTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case foundAccounts(
			active: IdentifiedArrayOf<Profile.Network.Account>,
			inactive: IdentifiedArrayOf<Profile.Network.Account>
		)
		case failedToDerivePublicKey
	}

	// MARK: - Destination
	public struct Destination: DestinationReducer {
		public enum State: Hashable, Sendable {
			case derivePublicKeys(DerivePublicKeys.State)
		}

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

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadIndicesUsedByFactorSourceResult(.failure(error)):
			let errorMsg = "Failed to load indices used by factor source, error: \(error)"
			loggerGlobal.error(.init(stringLiteral: errorMsg))
			return .send(.delegate(.failedToDerivePublicKey))

		case let .loadIndicesUsedByFactorSourceResult(.success(indicesUsedByFactorSource)):
			state.networkID = indicesUsedByFactorSource.currentNetworkID
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

			switch state.mode {
			case .privateHD:
				return derivePublicKeys(state: &state)
			case .factorSourceWithID:
				state.status = .loadingFactorSource
				let id = state.factorSourceIDFromHash
				state.mode = .factorSourceWithID(id: id, .loading)
				return .run { [networkID = state.networkID, forOlympiaAccounts = state.forOlympiaAccounts] send in
					let result = await TaskResult<IndicesUsedByFactorSource> {
						try await factorSourcesClient.indicesOfEntitiesControlledByFactorSource(
							.init(
								entityKind: .account,
								factorSourceID: id.embed(),
								derivationPathScheme: forOlympiaAccounts ? .bip44Olympia : .cap26,
								networkID: networkID
							)
						)
					}
					await send(.internal(.loadIndicesUsedByFactorSourceResult(result)))
				}
			}

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

				return .run { send in
					let accounts = try await publicHDKeys.enumerated().asyncMap { localOffset, publicHDKey in
						let offset = localOffset + globalOffset
						let appearanceID = await accountsClient.nextAppearanceID(networkID, offset)
						return try Profile.Network.Account(
							networkID: networkID,
							factorInstance: HierarchicalDeterministicFactorInstance(
								factorSourceID: id,
								publicHDKey: publicHDKey
							),
							displayName: "Unnamed", // FIXME: Strings
							extraProperties: .init(
								appearanceID: appearanceID,
								// We will be replacing the `depositRule` with one fetched from GW
								// in `scan` step later on.
								onLedgerSettings: .unknown
							)
						)
					}.asIdentifiable()

					await send(.internal(.startScan(accounts: accounts)))
				} catch: { error, send in
					let errorMsg = "Failed to create account, error: \(error)"
					loggerGlobal.critical(.init(stringLiteral: errorMsg))
					assertionFailure(errorMsg)
					await send(.delegate(.failedToDerivePublicKey))
				}

			case .failedToDerivePublicKey:
				return .send(.delegate(.failedToDerivePublicKey))
			}

		default: return .none
		}
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
				try LegacyOlympiaBIP44LikeDerivationPath(
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
			return .send(.delegate(.failedToDerivePublicKey))
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
				return .send(.delegate(.failedToDerivePublicKey))
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
		accounts: IdentifiedArrayOf<Profile.Network.Account>,
		state: inout State
	) -> Effect<Action> {
		assert(accounts.count == batchSize)
		state.status = .scanningNetworkForActiveAccounts
		state.destination = nil
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
		}
	}
}

// MARK: - OnLedgerSyncOfAccounts
public struct OnLedgerSyncOfAccounts: Sendable, Hashable {
	/// Inactive virtual accounts, unknown to the Ledger OnNetwork.
	public let inactive: IdentifiedArrayOf<Profile.Network.Account>
	/// Accounts known to the Ledger OnNetwork, with state updated according to that OnNetwork.
	public let active: IdentifiedArrayOf<Profile.Network.Account>
}

extension OnLedgerEntitiesClient {
	public func syncThirdPartyDepositWithOnLedgerSettings(
		account: inout Profile.Network.Account
	) async throws {
		guard let ruleOfAccount = try await getOnLedgerCustomizedThirdPartyDepositRule(addresses: [account.address]).first else {
			return
		}
		account.onLedgerSettings.thirdPartyDeposits.depositRule = ruleOfAccount.rule
	}

	public func syncThirdPartyDepositWithOnLedgerSettings(
		addressesOf accounts: IdentifiedArrayOf<Profile.Network.Account>
	) async throws -> OnLedgerSyncOfAccounts {
		let activeAddresses: [CustomizedOnLedgerThirdPartDepositForAccount]
		do {
			activeAddresses = try await getOnLedgerCustomizedThirdPartyDepositRule(addresses: accounts.map(\.accountAddress))
		} catch is GatewayAPIClient.EmptyEntityDetailsResponse {
			return OnLedgerSyncOfAccounts(inactive: accounts, active: [])
		} catch {
			throw error
		}
		var inactive: IdentifiedArrayOf<Profile.Network.Account> = []
		var active: IdentifiedArrayOf<Profile.Network.Account> = []
		for account in accounts { // iterate with `accounts` to retain insertion order.
			if let onLedgerActiveAccount = activeAddresses.first(where: { $0.address == account.address }) {
				var activeAccount = account
				activeAccount.onLedgerSettings.thirdPartyDeposits.depositRule = onLedgerActiveAccount.rule
				active.append(activeAccount)
			} else {
				inactive.append(account)
			}
		}
		return .init(inactive: inactive, active: active)
	}

	public struct CustomizedOnLedgerThirdPartDepositForAccount: Sendable, Hashable {
		public let address: AccountAddress
		public let rule: Profile.Network.Account.OnLedgerSettings.ThirdPartyDeposits.DepositRule
	}

	public func getOnLedgerCustomizedThirdPartyDepositRule(
		addresses: some Collection<AccountAddress>
	) async throws -> [CustomizedOnLedgerThirdPartDepositForAccount] {
		try await self.getAccounts(
			Array(addresses),
			// actually we wanna `resourceMetadataKeys` as well here, but we cannot since
			// the count will exceed `EntityMetadataKey.maxAllowedKeys`.
			metadataKeys: [.ownerBadge, .ownerKeys],
			cachingStrategy: .readFromLedgerSkipWrite
		)
		.compactMap { (onLedgerAccount: OnLedgerEntity.Account) -> CustomizedOnLedgerThirdPartDepositForAccount? in
			let address = onLedgerAccount.address
			guard
				case let metadata = onLedgerAccount.metadata,
				let ownerKeys = metadata.ownerKeys,
				let ownerBadge = metadata.ownerBadge
			else {
				//                    return CustomizedOnLedgerThirdPartDepositForAccount(address: address, rule: nil)
				return nil
			}

			func hasStateChange(_ list: OnLedgerEntity.Metadata.ValueAtStateVersion<some Any>) -> Bool {
				list.lastUpdatedAtStateVersion > 0
			}
			let isActive = hasStateChange(ownerKeys) || hasStateChange(ownerBadge)
			guard isActive, let rule = onLedgerAccount.details?.depositRule else {
				//                    return CustomizedOnLedgerThirdPartDepositForAccount(address: address, rule: nil)
				return nil
			}
			return CustomizedOnLedgerThirdPartDepositForAccount(address: address, rule: rule)
		}
	}
}

extension DerivationPath {
	var index: HD.Path.Component.Child.Value {
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

// MARK: - Profile.Network.Account + Comparable
extension Profile.Network.Account: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.derivationIndex < rhs.derivationIndex
	}
}

extension Profile.Network.Account {
	var derivationIndex: HD.Path.Component.Child.Value {
		switch securityState {
		case let .unsecured(uec): uec.transactionSigning.derivationPath.index
		}
	}
}
