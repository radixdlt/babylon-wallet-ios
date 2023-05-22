import AddLedgerFactorSourceFeature
import Cryptography
import FactorSourcesClient
import FeaturePrelude
import ImportLegacyWalletClient
import LedgerHardwareWalletClient
import Profile
import RadixConnectClient
import RadixConnectModels
import SharedModels

// MARK: - ImportOlympiaLedgerAccountsAndFactorSources
public struct ImportOlympiaLedgerAccountsAndFactorSources: Sendable, FeatureReducer {
	public struct LedgerWithAccounts: Sendable, Hashable {
		public let name: String?
		public let isLedgerNew: Bool
		public let model: FactorSource.LedgerHardwareWallet.DeviceModel
		public var displayName: String {
			if let name {
				return "\(name) (\(model.rawValue))"
			} else {
				return model.rawValue
			}
		}

		public let id: FactorSource.ID
		public let migratedAccounts: NonEmpty<OrderedSet<MigratedAccount>>
	}

	public struct State: Sendable, Hashable {
		/// unverified, to verify and migrate
		public var unverified: Set<OlympiaAccountToMigrate>

		/// verified but not yet migrated, to be migrated/converted
		public var verifiedToBeMigrated: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>?

		/// verified and migrated
		public var ledgersWithAccounts: OrderedSet<LedgerWithAccounts> = []

		@PresentationState
		public var addLedgerFactorSource: AddLedgerFactorSource.State?

		public init(
			hardwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		) {
			precondition(hardwareAccounts.allSatisfy { $0.accountType == .hardware })
			self.unverified = Set(hardwareAccounts.elements)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case skipRestOfTheAccounts
	}

	public enum InternalAction: Sendable, Equatable {
		case migratedOlympiaHardwareAccounts(LedgerWithAccounts)
	}

	public enum ChildAction: Sendable, Equatable {
		case addLedgerFactorSource(PresentationAction<AddLedgerFactorSource.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(
			ledgersWithAccounts: OrderedSet<LedgerWithAccounts>,
			unvalidatedAccounts: Set<OlympiaAccountToMigrate>
		)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.importLegacyWalletClient) var importLegacyWalletClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public var body: some ReducerProtocolOf<ImportOlympiaLedgerAccountsAndFactorSources> {
		Reduce(core)
			.ifLet(\.$addLedgerFactorSource, action: /Action.child .. ChildAction.addLedgerFactorSource) {
				AddLedgerFactorSource()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .skipRestOfTheAccounts:
			return .send(.delegate(.completed(
				ledgersWithAccounts: state.ledgersWithAccounts,
				unvalidatedAccounts: state.unverified
			)))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .migratedOlympiaHardwareAccounts(ledgerWithAccounts):
			loggerGlobal.notice("Adding Ledger with accounts...")
			state.ledgersWithAccounts.append(ledgerWithAccounts)
			state.verifiedToBeMigrated = nil

			return continueWithRestOfAccountsIfNeeded(state: &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .addLedgerFactorSource(.presented(.delegate(.completed(ledger)))):
			return convertHardwareAccountsToBabylon(
				isLedgerNew: true,
				ledger: ledger,
				state
			)

		case let .addLedgerFactorSource(.presented(.delegate(.alreadyExists(ledger)))):

			return convertHardwareAccountsToBabylon(
				isLedgerNew: false,
				ledger: ledger,
				state
			)

		default: return .none
		}
	}

	private func convertHardwareAccountsToBabylon(
		isLedgerNew: Bool,
		ledger: LedgerFactorSource,
		_ state: State
	) -> EffectTask<Action> {
		guard let olympiaAccounts = state.verifiedToBeMigrated else {
			assertionFailure("Expected verified accounts to migrated")
			return .none
		}
		loggerGlobal.notice("Converting hardware accounts to babylon...")
		let ledgerName = ledger.label.rawValue

		let model = ledger.model

		return .run { send in
			// Migrates and saved all accounts to Profile
			let migrated = try await importLegacyWalletClient.migrateOlympiaHardwareAccountsToBabylon(
				.init(
					olympiaAccounts: Set(olympiaAccounts.elements),
					ledgerFactorSourceID: ledger.id
				)
			)
			loggerGlobal.notice("Converted #\(migrated.babylonAccounts.count) accounts to babylon! ✅")
			let addedLedgerWithAccounts = LedgerWithAccounts(
				name: ledgerName,
				isLedgerNew: isLedgerNew,
				model: model,
				id: ledger.id,
				migratedAccounts: migrated.accounts
			)

			await send(.internal(.migratedOlympiaHardwareAccounts(addedLedgerWithAccounts)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to migrate accounts to babylon, error: \(error)")
			errorQueue.schedule(error)
		}
	}

	private func continueWithRestOfAccountsIfNeeded(state: inout State) -> EffectTask<Action> {
		if state.unverified.isEmpty {
			loggerGlobal.notice("state.unverified.isEmpty skipping sending importOlympiaDevice request => delegate completed!")

			return .send(.delegate(.completed(
				ledgersWithAccounts: state.ledgersWithAccounts,
				unvalidatedAccounts: []
			)))
		} else {
			loggerGlobal.notice("state.unverified not empty #\(state.unverified.count) unverfied remain, preparing to send importOlympiaDevice request...")

			state.addLedgerFactorSource = .some(.init())

			return .none
		}
	}
}

extension FactorSource.LedgerHardwareWallet.DeviceModel {
	init(model: P2P.LedgerHardwareWallet.Model) {
		switch model {
		case .nanoS: self = .nanoS
		case .nanoX: self = .nanoX
		case .nanoSPlus: self = .nanoSPlus
		}
	}
}
