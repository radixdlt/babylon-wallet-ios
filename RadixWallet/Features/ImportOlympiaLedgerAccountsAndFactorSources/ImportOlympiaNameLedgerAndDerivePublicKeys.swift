import ComposableArchitecture

// MARK: - ImportOlympiaNameLedgerAndDerivePublicKeys
public struct ImportOlympiaNameLedgerAndDerivePublicKeys: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let networkID: NetworkID

		public let olympiaAccounts: Set<OlympiaAccountToMigrate>

		public var nameLedger: NameLedgerFactorSource.State? = nil

		@PresentationState
		public var derivePublicKeys: DerivePublicKeys.State? = nil

		public init(networkID: NetworkID, olympiaAccounts: Set<OlympiaAccountToMigrate>, deviceInfo: LedgerDeviceInfo) {
			self.networkID = networkID
			self.olympiaAccounts = olympiaAccounts
			self.nameLedger = .init(deviceInfo: deviceInfo)
		}

		public init(networkID: NetworkID, olympiaAccounts: Set<OlympiaAccountToMigrate>, ledger: LedgerHardwareWalletFactorSource) {
			self.networkID = networkID
			self.olympiaAccounts = olympiaAccounts

			showDerivePublicKeys(using: ledger)
		}

		mutating func showDerivePublicKeys(using ledger: LedgerHardwareWalletFactorSource) {
			derivePublicKeys = .init(ledger: ledger, olympiaAccounts: olympiaAccounts, networkID: networkID)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case nameLedger(NameLedgerFactorSource.Action)
		case derivePublicKeys(PresentationAction<DerivePublicKeys.Action>)
	}

	public enum InternalAction: Sendable, Equatable {
		/// Saved the newly added Ledger device
		case savedNewLedger(LedgerHardwareWalletFactorSource)
	}

	public enum DelegateAction: Sendable, Equatable {
		case savedNewLedger(LedgerHardwareWalletFactorSource)
		case failedToSaveNewLedger
		case derivePublicKeys(DerivePublicKeys.DelegateAction)
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.nameLedger, action: /Action.child .. ChildAction.nameLedger) {
				NameLedgerFactorSource()
			}
			.ifLet(\.$derivePublicKeys, action: /Action.child .. ChildAction.derivePublicKeys) {
				DerivePublicKeys()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.run { _ in
				await dismiss()
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .nameLedger(.delegate(.complete(ledger))):
			saveNewLedger(ledger)

		case .nameLedger(.delegate(.failedToCreateLedgerFactorSource)):
			.send(.delegate(.failedToSaveNewLedger))

		case let .derivePublicKeys(.presented(.delegate(derivePublicKeysAction))):
			.send(.delegate(.derivePublicKeys(derivePublicKeysAction)))

		default:
			.none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .savedNewLedger(ledger):
			state.showDerivePublicKeys(using: ledger)
			return .none
		}
	}

	private func saveNewLedger(_ ledger: LedgerHardwareWalletFactorSource) -> Effect<Action> {
		.run { send in
			try await factorSourcesClient.saveFactorSource(ledger.embed())
			loggerGlobal.notice("Saved Ledger factor source! ✅")
			await send(.delegate(.savedNewLedger(ledger)))
			await send(.internal(.savedNewLedger(ledger)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to save Factor Source, error: \(error)")
			errorQueue.schedule(error)
		}
	}
}

// MARK: - Helper
extension DerivePublicKeys.State {
	fileprivate init(ledger: LedgerHardwareWalletFactorSource, olympiaAccounts: Set<OlympiaAccountToMigrate>, networkID: NetworkID) {
		self.init(
			derivationPathOption: .knownPaths(
				olympiaAccounts.map { $0.path.wrapAsDerivationPath() },
				networkID: networkID
			),
			factorSourceOption: .specific(ledger.embed()),
			purpose: .importLegacyAccounts
		)
	}
}
