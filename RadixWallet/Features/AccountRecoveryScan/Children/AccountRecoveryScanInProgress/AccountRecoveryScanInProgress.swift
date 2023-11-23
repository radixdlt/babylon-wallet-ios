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

		/// Attention! This CANNOT be changed into the `destination` pattern we use elsewhere, due to
		/// the "TCE Send"-bug, we never ever receive the event `internal(.foundAccounts` if we
		/// use destination pattern with the `DestinationReducer` like we ought to. Cyon is about to send
		/// a minimum showcasing example of the "TCA Send" bug to Pointfree, stay tuned, in the meantime
		/// we will have to live with this.
		@PresentationState
		public var derivePublicKeys: DerivePublicKeys.State?

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
		case delayScan(accounts: IdentifiedArrayOf<Profile.Network.Account>)
		case foundAccounts(
			active: IdentifiedArrayOf<Profile.Network.Account>,
			inactive: IdentifiedArrayOf<Profile.Network.Account>
		)
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case scanMore
		case continueTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case foundAccounts(
			active: IdentifiedArrayOf<Profile.Network.Account>,
			inactive: IdentifiedArrayOf<Profile.Network.Account>
		)
	}

	public enum ChildAction: Sendable, Equatable {
		/// Attention! If you change this to the `destination` pattern we use elsewhere this feature breaks due to "TCA Send"-bug
		case derivePublicKeys(PresentationAction<DerivePublicKeys.Action>)
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			/// Attention! If you change this to the `destination` pattern we use elsewhere this feature breaks due to "TCA Send"-bug
			.ifLet(\.$derivePublicKeys, action: /Action.child .. ChildAction.derivePublicKeys) {
				DerivePublicKeys()
			}
	}

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
			state.factorSource = .success(factorSource)
			return derivePublicKeys(using: factorSource, state: &state)

		case let .delayScan(accounts):
			return scanOnLedger(accounts: accounts, state: &state)

		case let .foundAccounts(active, inactive):
			loggerGlobal.notice("✅ .internal(.foundAccounts))")
			state.status = .scanComplete
			state.active.append(contentsOf: active)
			state.inactive.append(contentsOf: inactive)
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
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

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		/// Attention! If you change this to the `destination` pattern we use elsewhere this feature breaks due to "TCA Send"-bug
		case let .derivePublicKeys(.presented(.delegate(delegateAction))):
			loggerGlobal.notice("Finish deriving public keys")
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

				// We delay because it is bad UX for user to see DerivingPublicKeys view presented
				// and dismissed so fast.
				return delayedMediumEffect(internal: .delayScan(accounts: accounts))

			case .failedToDerivePublicKey:
				fatalError("failed to derive keys")
			}

		case .derivePublicKeys(.dismiss):
			return .none
		case .derivePublicKeys(.presented(_)):
			return .none
		}
	}
}

extension AccountRecoveryScanInProgress {
	private func scanOnLedger(accounts: IdentifiedArrayOf<Profile.Network.Account>, state: inout State) -> Effect<Action> {
		assert(accounts.count == accRecScanBatchSize)
		state.derivePublicKeys = nil
		state.status = .scanningNetworkForActiveAccounts

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
		state.status = .derivingPublicKeys
		state.derivePublicKeys = .init(
			derivationPathOption: .knownPaths(
				derivationPaths,
				networkID: networkID
			),
			factorSourceOption: .specific(
				factorSource
			),
			purpose: .createEntity(kind: .account)
		)

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
