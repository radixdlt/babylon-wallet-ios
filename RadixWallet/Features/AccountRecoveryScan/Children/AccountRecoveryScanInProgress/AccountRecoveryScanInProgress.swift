import Sargon

// MARK: - AccountRecoveryScanInProgress
struct AccountRecoveryScanInProgress: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum Status: Sendable, Hashable {
			case new
			case loadingFactorSource
			case derivingPublicKeys
			case scanningNetworkForActiveAccounts
			case scanComplete
		}

		var mode: Mode
		var status: Status
		var networkID: NetworkID = .mainnet
		var batchNumber: Int = 0
		var maxIndex: HdPathComponent? = nil

		var indicesOfAlreadyUsedEntities: OrderedSet<HdPathComponent> = []
		let forOlympiaAccounts: Bool
		var active: IdentifiedArrayOf<Account> = []
		var inactive: IdentifiedArrayOf<Account> = []
		var deleted: IdentifiedArrayOf<Account> = []

		enum Mode: Sendable, Hashable {
			case createProfile(PrivateHierarchicalDeterministicFactorSource)
			case addAccounts(factorSourceId: FactorSourceIDFromHash, Loadable<FactorSource> = .idle)
		}

		var factorSourceIDFromHash: FactorSourceIDFromHash {
			switch mode {
			case let .createProfile(privateHD):
				privateHD.factorSource.id
			case let .addAccounts(id, _):
				id
			}
		}

		init(
			mode: Mode,
			forOlympiaAccounts: Bool = false,
			status: Status = .new
		) {
			self.mode = mode
			self.forOlympiaAccounts = forOlympiaAccounts
			self.status = status
		}
	}

	enum InternalAction: Sendable, Equatable {
		case loadIndicesUsedByFactorSourceResult(TaskResult<IndicesUsedByFactorSource>)
		case startScan(accounts: IdentifiedArrayOf<Account>)
		case derivedPublicKeys([HierarchicalDeterministicPublicKey])
		case foundAccounts(
			active: IdentifiedArrayOf<Account>,
			inactive: IdentifiedArrayOf<Account>,
			deleted: IdentifiedArrayOf<Account>
		)
		case initiate
	}

	enum ViewAction: Sendable, Equatable {
		case onFirstAppear
		case scanMore
		case continueTapped
		case closeButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case foundAccounts(
			active: IdentifiedArrayOf<Account>,
			inactive: IdentifiedArrayOf<Account>,
			deleted: IdentifiedArrayOf<Account>
		)
		case failed
		case close
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .initiate:
			switch state.mode {
			case .createProfile:
				return derivePublicKeysEffect(state: &state)
			case .addAccounts:
				state.status = .loadingFactorSource
				let id = state.factorSourceIDFromHash
				state.mode = .addAccounts(factorSourceId: id, .loading)
				return .run { [forOlympiaAccounts = state.forOlympiaAccounts] send in
					let result = await TaskResult<IndicesUsedByFactorSource> {
						try await factorSourcesClient.indicesOfEntitiesControlledByFactorSource(
							.init(
								entityKind: .account,
								factorSourceID: id.asGeneral,
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

			state.mode = .addAccounts(
				factorSourceId: state.factorSourceIDFromHash,
				.success(
					indicesUsedByFactorSource.factorSource
				)
			)

			state.indicesOfAlreadyUsedEntities = indicesUsedByFactorSource.indices
			return derivePublicKeysEffect(state: &state)

		case let .startScan(accounts):
			return scanOnLedger(accounts: accounts, state: &state)

		case let .derivedPublicKeys(publicKeys):
			return handleDerivedPublicKeysEffect(state: state, publicKeys: publicKeys)

		case let .foundAccounts(active, inactive, deleted):
			state.batchNumber += 1
			state.status = .scanComplete
			state.active.append(contentsOf: active)
			state.inactive.append(contentsOf: inactive)
			state.deleted.append(contentsOf: deleted)
			return .none
		}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstAppear:
			guard state.status == .new else {
				return .none
			}

			/// A temporary hack to fix ABW-2657. When the deriving keys slide up will not show
			return delayedMediumEffect(for: .internal(.initiate))

		case .scanMore:
			loggerGlobal.debug("Scan more requested.")
			return derivePublicKeysEffect(state: &state)

		case .continueTapped:
			if let maxActive = state.active.max() {
				let inactiveInBetweenActive = state.inactive.filter {
					$0.derivationIndex < maxActive.derivationIndex
				}
				return .send(.delegate(.foundAccounts(
					active: state.active,
					inactive: inactiveInBetweenActive,
					deleted: state.deleted
				)))
			} else {
				return .send(.delegate(.foundAccounts(active: [], inactive: [], deleted: [])))
			}

		case .closeButtonTapped:
			return .send(.delegate(.close))
		}
	}

	private func handleDerivedPublicKeysEffect(state: State, publicKeys: [HierarchicalDeterministicPublicKey]) -> Effect<Action> {
		let networkID = state.networkID
		let globalOffset = state.active.count + state.inactive.count
		loggerGlobal.debug("Creating accounts with networkID: \(networkID)")
		return .run { [mode = state.mode, factorSourceId = state.factorSourceIDFromHash] send in
			let accounts = await publicKeys.enumerated().asyncMap { localOffset, publicHDKey in
				let offset = localOffset + globalOffset
				let appearanceID = await getAccountAppearanceID(
					mode: mode,
					offset: offset,
					networkID: networkID
				)
				return Account(
					networkID: networkID,
					factorInstance: .init(factorSourceId: factorSourceId, publicKey: publicHDKey),
					displayName: .init(value: L10n.AccountRecoveryScan.InProgress.nameOfRecoveredAccount),
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
	}

	private func getAccountAppearanceID(
		mode: State.Mode,
		offset: Int,
		networkID: NetworkID
	) async -> AppearanceID {
		switch mode {
		case .createProfile:
			return AppearanceID.fromNumberOfAccounts(offset)
		case .addAccounts:
			@Dependency(\.accountsClient) var accountsClient
			return await accountsClient.nextAppearanceID(networkID, offset)
		}
	}
}

extension AccountRecoveryScanInProgress {
	private func nextDerivationPaths(state: inout State) throws -> OrderedSet<DerivationPath> {
		let networkID = state.networkID

		let derivationIndices = generateIntegers(
			start: state.maxIndex?.indexInLocalKeySpace() ?? 0,
			count: batchSize,
			excluding: state.indicesOfAlreadyUsedEntities.map { $0.indexInLocalKeySpace() }
		)
		assert(derivationIndices.count == batchSize)
		state.maxIndex = try HdPathComponent(
			localKeySpace: derivationIndices.max()! + 1,
			keySpace: .unsecurified(isHardened: true)
		)

		let paths = try derivationIndices.map { index in
			if state.forOlympiaAccounts {
				try Bip44LikePath(
					index: HdPathComponent.unsecurifiedComponent(Unsecurified.hardenedComponent(UnsecurifiedHardened(localKeySpace: index)))
				)
				.asGeneral
			} else {
				try AccountPath(
					networkID: networkID,
					keyKind: .transactionSigning,
					index: Hardened.unsecurified(UnsecurifiedHardened(localKeySpace: index))
				).asGeneral
			}
		}

		return try OrderedSet(validating: paths)
	}

	private func derivePublicKeysEffect(
		state: inout State
	) -> Effect<Action> {
		state.status = .derivingPublicKeys
		let derivationPaths: OrderedSet<DerivationPath>
		do {
			derivationPaths = try nextDerivationPaths(state: &state)
		} catch {
			let errorMsg = "Failed to calculate next derivation paths"
			loggerGlobal.error(.init(stringLiteral: errorMsg))
			assertionFailure(errorMsg)
			return .send(.delegate(.failed))
		}
		let source: DerivePublicKeysSource
		switch state.mode {
		case let .addAccounts(id, loadableState):
			switch loadableState {
			case .success:
				source = .factorSource(id)
			default:
				let errorMsg = "Discrepancy! Expected to loaded the factor source"
				loggerGlobal.error(.init(stringLiteral: errorMsg))
				assertionFailure(errorMsg)
				return .send(.delegate(.failed))
			}
		case let .createProfile(privateHDFactorSource):
			source = .mnemonic(privateHDFactorSource.mnemonicWithPassphrase)
		}

		return .run { send in
			let result = try await SargonOS.shared.derivePublicKeys(derivationPaths: Array(derivationPaths), source: source)
			await send(.internal(.derivedPublicKeys(result)))
		} catch: { _, send in
			await send(.delegate(.failed))
		}
	}

	private func scanOnLedger(
		accounts: IdentifiedArrayOf<Account>,
		state: inout State
	) -> Effect<Action> {
		assert(accounts.count == batchSize)
		state.status = .scanningNetworkForActiveAccounts
		loggerGlobal.debug("Scanning ledger with accounts with addresses: \(accounts.map(\.address))")
		return .run { [networkID = state.networkID] send in
			let deletedAccountAddresses: [AccountAddress] = try await SargonOS.shared
				.checkAccountsDeletedOnLedger(
					networkId: networkID,
					accountAddresses: accounts.map(\.address)
				)
				.compactMap { accountAddress, isDeleted in
					isDeleted ? accountAddress : nil
				}

			let deletedAccounts = accounts.filter {
				deletedAccountAddresses.contains($0.address)
			}
			.asIdentified()

			let filteredAccounts = accounts.filter {
				!deletedAccountAddresses.contains($0.address)
			}
			.asIdentified()

			let onLedgerSyncOfAccounts = try await onLedgerEntitiesClient
				.syncThirdPartyDepositWithOnLedgerSettings(
					addressesOf: filteredAccounts
				)

			await send(
				.internal(
					.foundAccounts(
						active: onLedgerSyncOfAccounts.active,
						inactive: onLedgerSyncOfAccounts.inactive,
						deleted: deletedAccounts
					)
				)
			)
		} catch: { error, send in
			loggerGlobal.error("Failed to scan network, error: \(error)")
			await send(.delegate(.failed))
		}
	}
}
