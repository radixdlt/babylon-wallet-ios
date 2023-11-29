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
		public var networkID: NetworkID = .mainnet
		public var batchNumber: Int = 0
		public var maxIndex: HD.Path.Component.Child.Value? = nil

		public var indicesOfAlreadyUsedEntities: OrderedSet<HD.Path.Component.Child.Value> = []
		public let scheme: DerivationScheme
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
			scheme: DerivationScheme
		) {
			self.mode = mode
			self.scheme = scheme
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
	@Dependency(\.continuousClock) var clock
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadIndicesUsedByFactorSourceResult(.failure(error)):
			let errorMsg = "Failed to load indices used by factor source, error: \(error)"
			loggerGlobal.error(.init(stringLiteral: errorMsg))
			return .send(.delegate(.failedToDerivePublicKey))

		case let .loadIndicesUsedByFactorSourceResult(.success(indicesUsedByFactorSource)):
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
			loggerGlobal.debug("AccountRecoveryScanInProgress: onFirstAppear")

			switch state.mode {
			case .privateHD:
				return derivePublicKeys(state: &state)
			case .factorSourceWithID:
				state.status = .loadingFactorSource
				let id = state.factorSourceIDFromHash
				state.mode = .factorSourceWithID(id: id, .loading)
				return .run { [networkID = state.networkID] send in
					let result = await TaskResult<IndicesUsedByFactorSource> {
						try await factorSourcesClient.indicesOfEntitiesControlledByFactorSource(
							.init(
								entityKind: .account,
								factorSourceID: id.embed(),
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
		switch presentedAction {
		case let .derivePublicKeys(.delegate(delegateAction)):
			loggerGlobal.notice("Finish deriving public keys => `state.destination = nil`")
			switch delegateAction {
			case let .derivedPublicKeys(publicHDKeys, factorSourceID, networkID):
				let id = state.factorSourceIDFromHash
				assert(factorSourceID == id.embed())
				assert(networkID == state.networkID)
				return .run { send in
					let accounts = await publicHDKeys.enumerated().asyncMap { offset, publicHDKey in
						let appearanceID = await accountsClient.nextAppearanceID(networkID, offset)
						let account = try! Profile.Network.Account(
							networkID: networkID,
							factorInstance: .init(
								factorSourceID: id,
								publicHDKey: publicHDKey
							),
							displayName: "Unnamed",
							extraProperties: .init(appearanceID: appearanceID)
						)
						return account
					}.asIdentifiable()
					try? await clock.sleep(for: .milliseconds(300))
					await send(.internal(.startScan(accounts: accounts)))
				}

			case .failedToDerivePublicKey:
				return .send(.delegate(.failedToDerivePublicKey))
			}

		default: return .none
		}
	}
}

public func generateElements<Element>(
	start: Element,
	step: (Element) -> Element,
	count: Int,
	shouldInclude: (Element) -> Bool
) -> OrderedSet<Element> where Element: Hashable {
	var next = start
	var elements: OrderedSet<Element> = []
	while elements.count != count {
		defer { next = step(next) }
		guard shouldInclude(next) else { continue }
		elements.append(next)
	}
	assert(elements.count == count)
	return elements
}

public func generateIntegers<Integer>(
	start: Integer,
	count: Int,
	shouldInclude: @escaping (Integer) -> Bool
) -> OrderedSet<Integer> where Integer: FixedWidthInteger {
	generateElements(start: start, step: { $0 + 1 }, count: count, shouldInclude: shouldInclude)
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

extension AccountRecoveryScanInProgress {
	private func derivePublicKeys(
		state: inout State
	) -> Effect<Action> {
		let networkID = state.networkID
		let used = state.indicesOfAlreadyUsedEntities

		let derivationIndices = generateIntegers(
			start: state.maxIndex ?? 0,
			count: batchSize,
			shouldInclude: { !used.contains($0) }
		)

		assert(derivationIndices.count == batchSize)
		state.maxIndex = derivationIndices.max()!

		let derivationPaths = try! OrderedSet(validating: derivationIndices.map {
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
		})

		state.status = .derivingPublicKeys
		loggerGlobal.debug("Settings destination to derivePublicKeys")
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
				return .none
			}
		case let .privateHD(privateHDFactorSource):
			factorSourceOption = .specificPrivateHDFactorSource(privateHDFactorSource)
		}

		state.destination = .derivePublicKeys(.init(
			derivationPathOption: .knownPaths(
				Array(derivationPaths),
				networkID: networkID
			),
			factorSourceOption: factorSourceOption,
			purpose: .createEntity(kind: .account)
		))

		return .none
	}

	private func scanOnLedger(accounts: IdentifiedArrayOf<Profile.Network.Account>, state: inout State) -> Effect<Action> {
		assert(accounts.count == batchSize)
		state.status = .scanningNetworkForActiveAccounts
		state.destination = nil
		return .run { send in
			let (active, inactive) = try await performScan(accounts: accounts)
			loggerGlobal.notice("✅Finished scanning for accounts => send(.internal(.foundAccounts))")
			await send(.internal(.foundAccounts(active: active, inactive: inactive)))
		}
	}

	private func performScan(accounts: IdentifiedArrayOf<Profile.Network.Account>) async throws -> (active: IdentifiedArrayOf<Profile.Network.Account>, inactive: IdentifiedArrayOf<Profile.Network.Account>) {
		let accountAddresses: [AccountAddress] = accounts.map(\.address)
		let engineAddresses: [Address] = accountAddresses.map(\.asGeneral)

		do {
			let addressOfActiveAccounts: [AccountAddress] = try await onLedgerEntitiesClient.getEntities(
				engineAddresses,
				[.ownerBadge, .ownerKeys],
				nil,
				true // force to refresh
			).compactMap { (onLedgerEntity: OnLedgerEntity) -> AccountAddress? in
				guard
					let onLedgerAccount = onLedgerEntity.account,
					case let metadata = onLedgerAccount.metadata,
					let ownerKeys = metadata.ownerKeys,
					let ownerBadge = metadata.ownerBadge
				else { return nil }

				func hasStateChange(_ list: OnLedgerEntity.Metadata.ValueAtStateVersion<some Any>) -> Bool {
					list.lastUpdatedAtStateVersion > 0
				}
				let isActive = hasStateChange(ownerKeys) || hasStateChange(ownerBadge)
				guard isActive else {
					return nil
				}
				return onLedgerAccount.address
			}

			var active: IdentifiedArrayOf<Profile.Network.Account> = []
			var inactive: IdentifiedArrayOf<Profile.Network.Account> = []
			for account in accounts {
				if addressOfActiveAccounts.contains(where: { $0 == account.address }) {
					active.append(account)
				} else {
					inactive.append(account)
				}
			}
			return (active, inactive)
		} catch is GatewayAPIClient.EmptyEntityDetailsResponse {
			return (active: [], inactive: accounts)
		} catch {
			throw error
		}
	}
}

extension DerivationPath {
	var index: HD.Path.Component.Child.Value {
		try! hdFullPath().children.last!.nonHardenedValue
	}
}
