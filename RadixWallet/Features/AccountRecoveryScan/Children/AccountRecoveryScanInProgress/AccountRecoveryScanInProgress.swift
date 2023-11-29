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
		public let networkID: NetworkID
		public var offset: Int
		public let scheme: DerivationScheme
		public var active: IdentifiedArrayOf<Profile.Network.Account> = []
		public var inactive: IdentifiedArrayOf<Profile.Network.Account> = []

		@PresentationState
		public var destination: Destination.State? = nil

		public enum FactorSourceOrigin: Sendable, Hashable {
			case privateHD(PrivateHDFactorSource)
			case loadFactorSourceWithID(FactorSourceID.FromHash)
		}

		public enum FactorSourceStatus: Sendable, Hashable {
			case privateHD(PrivateHDFactorSource)
			case factorSourceWithID(Loadable<FactorSource>, id: FactorSourceID.FromHash)

			init(origin: FactorSourceOrigin) {
				switch origin {
				case let .loadFactorSourceWithID(id):
					self = .factorSourceWithID(.idle, id: id)
				case let .privateHD(privateHD):
					self = .privateHD(privateHD)
				}
			}
		}

		public var factorSourceIDFromHash: FactorSourceID.FromHash {
			switch factorSourceStatus {
			case let .privateHD(privateHD):
				privateHD.factorSource.id
			case let .factorSourceWithID(_, id):
				id
			}
		}

		public var factorSourceStatus: FactorSourceStatus

		public init(
			factorSourceOrigin: FactorSourceOrigin,
			offset: Int,
			scheme: DerivationScheme,
			networkID: NetworkID
		) {
			self.offset = offset
			self.factorSourceStatus = FactorSourceStatus(origin: factorSourceOrigin)
			self.scheme = scheme
			self.networkID = networkID
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case loadFactorSourceResult(TaskResult<FactorSource?>)
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
		case let .loadFactorSourceResult(.failure(error)):
			fatalError("error handling")

		case let .loadFactorSourceResult(.success(factorSource)):
			guard let factorSource else {
				fatalError("error handling")
			}
			state.factorSourceStatus = .factorSourceWithID(.success(factorSource), id: state.factorSourceIDFromHash)
			return derivePublicKeys(state: &state)

		case let .startScan(accounts):
			return scanOnLedger(accounts: accounts, state: &state)

		case let .foundAccounts(active, inactive):
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

			switch state.factorSourceStatus {
			case .privateHD:
				return derivePublicKeys(state: &state)
			case .factorSourceWithID:
				state.status = .loadingFactorSource
				let id = state.factorSourceIDFromHash
				state.factorSourceStatus = .factorSourceWithID(.loading, id: id)
				return .run { send in
					let result = await TaskResult<FactorSource?> {
						try await factorSourcesClient.getFactorSource(id: id.embed())
					}
					await send(.internal(.loadFactorSourceResult(result)))
				}
			}

		case .scanMore:
			loggerGlobal.debug("Scan more requested.")
			state.offset += accRecScanBatchSize
			return derivePublicKeys(state: &state)

		case .continueTapped:
			return .send(.delegate(.foundAccounts(active: state.active, inactive: state.inactive)))
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

extension AccountRecoveryScanInProgress {
	private func scanOnLedger(accounts: IdentifiedArrayOf<Profile.Network.Account>, state: inout State) -> Effect<Action> {
		assert(accounts.count == accRecScanBatchSize)
		state.status = .scanningNetworkForActiveAccounts
		state.destination = nil
		return .run { send in
			let (active, inactive) = try await performScan(accounts: accounts)
			loggerGlobal.notice("✅Finished scanning for accounts => send(.internal(.foundAccounts))")
			await send(.internal(.foundAccounts(active: active, inactive: inactive)))
		}
	}

	/// FIXME: This results in CancellationError, not only this but doing ANY thing that takes a bit of time inside of `scanOnLedger` results in
	/// CancellationError, e.g. `try await Task.sleep(for: .seconds(0.5))` results in CancellationError, which results in this
	/// Reducer never ever receiving `internal(.foundAccounts` event - aka "TCA Send" bug. I will have to write it in another manner...
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
			if active.isEmpty {
				let n = 3
				loggerGlobal.critical("MOCKING THAT \(n) accounts were active")
				let mockedActive = inactive.prefix(n)
				active.append(contentsOf: mockedActive)
				inactive.removeFirst(n)
			}
			return (active, inactive)
		} catch is GatewayAPIClient.EmptyEntityDetailsResponse {
			return (active: [], inactive: accounts)
		} catch {
			throw error
		}
	}

	private func derivePublicKeys(
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
		state.status = .derivingPublicKeys
		loggerGlobal.debug("Settings destination to derivePublicKeys")
		let factorSourceOption: DerivePublicKeys.State.FactorSourceOption

		switch state.factorSourceStatus {
		case let .factorSourceWithID(loadableState, _):
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
				derivationPaths,
				networkID: networkID
			),
			factorSourceOption: factorSourceOption,
			purpose: .createEntity(kind: .account)
		))

		return .none
	}

	private func slow() async {
		loggerGlobal.error("SLOW START")
		_ = await Task(priority: .background) {
			(0 ..< 100_000).map { _ in
				CryptoKit.Curve25519.PrivateKey().publicKey
			}
		}.value
		loggerGlobal.error("SLOW END")
	}
}

extension DerivationPath {
	var index: HD.Path.Component.Child.Value {
		try! hdFullPath().children.last!.nonHardenedValue
	}
}
