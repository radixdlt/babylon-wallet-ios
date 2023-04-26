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
	public struct AddedLedgerWithAccounts: Sendable, Hashable {
		public let name: String?
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
		public var addedLedgersWithAccounts: OrderedSet<AddedLedgerWithAccounts> = []

		public var failedToFindAnyLinks = false
		public var ledgerName = ""
		public var isWaitingForResponseFromLedger = false
		public var unnamedDeviceToAdd: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice?

		public init(
			hardwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		) {
			precondition(hardwareAccounts.allSatisfy { $0.accountType == .hardware })
			self.unverified = Set(hardwareAccounts.elements)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case sendAddLedgerRequestButtonTapped
		case skipRestOfTheAccounts
		case ledgerNameChanged(String)
		case confirmNameButtonTapped
		case skipNamingLedgerButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case gotLinksConnectionStatusUpdate([P2P.LinkConnectionUpdate])

		case validateLedgerBeforeNamingIt(P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice)
		case nameLedgerDeviceBeforeSavingIt(
			P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice
		)

		case failedToImportOlympiaLedger
		case addedFactorSource(FactorSource, FactorSource.LedgerHardwareWallet.DeviceModel, name: String?)

		case migratedOlympiaHardwareAccounts(AddedLedgerWithAccounts)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(
			addedLedgersWithAccounts: OrderedSet<AddedLedgerWithAccounts>,
			unvalidatedAccounts: Set<OlympiaAccountToMigrate>
		)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.importLegacyWalletClient) var importLegacyWalletClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:

			return .run { send in
				for try await linksConnectionUpdate in await radixConnectClient.getP2PLinksWithConnectionStatusUpdates() {
					guard !Task.isCancelled else {
						return
					}
					await send(.internal(.gotLinksConnectionStatusUpdate(linksConnectionUpdate)))
				}
			} catch: { error, _ in
				loggerGlobal.error("failed to get links updates, error: \(error)")
			}
		case .sendAddLedgerRequestButtonTapped:
			return continueWithRestOfAccountsIfNeeded(state: &state)

		case .skipRestOfTheAccounts:
			return .send(.delegate(.completed(
				addedLedgersWithAccounts: state.addedLedgersWithAccounts,
				unvalidatedAccounts: state.unverified
			)))

		case let .ledgerNameChanged(name):
			state.ledgerName = name
			return .none

		case .confirmNameButtonTapped:
			let name = state.ledgerName
			loggerGlobal.notice("Confirmed ledger name: '\(name)' => adding factor source")
			guard let device = state.unnamedDeviceToAdd else {
				assertionFailure("Expected device to name")
				return .none
			}
			return addFactorSource(
				name: name,
				unnamedDeviceToAdd: device
			)

		case .skipNamingLedgerButtonTapped:
			guard let device = state.unnamedDeviceToAdd else {
				assertionFailure("Expected device to name")
				return .none
			}
			return addFactorSource(
				name: nil,
				unnamedDeviceToAdd: device
			)
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .gotLinksConnectionStatusUpdate(linksConnectionStatusUpdate):
			loggerGlobal.notice("links connection status update: \(linksConnectionStatusUpdate)")
			let connectedLinks = linksConnectionStatusUpdate.filter(\.hasAnyConnectedPeers)
			state.failedToFindAnyLinks = connectedLinks.isEmpty
			return .none

		case let .nameLedgerDeviceBeforeSavingIt(device):
			state.unnamedDeviceToAdd = device
			return .none

		case .failedToImportOlympiaLedger:
			state.isWaitingForResponseFromLedger = false
			return .none

		case let .validateLedgerBeforeNamingIt(ledger):
			return validate(ledger, againstUnverifiedOf: &state)

		case let .addedFactorSource(factorSource, model, name):
			state.unnamedDeviceToAdd = nil
			state.ledgerName = ""
			guard let verifiedToMigrate = state.verifiedToBeMigrated else {
				assertionFailure("Expected verified accounts to migrated")
				return .none
			}
			loggerGlobal.notice("Converting hardware accounts to babylon...")
			return convertHardwareAccountsToBabylon(
				verifiedToMigrate,
				factorSource: factorSource,
				model: model,
				ledgerName: name
			)

		case let .migratedOlympiaHardwareAccounts(addedLedgerWithAccounts):
			loggerGlobal.notice("Adding Ledger with accounts...")
			state.addedLedgersWithAccounts.append(addedLedgerWithAccounts)
			state.verifiedToBeMigrated = nil

			return continueWithRestOfAccountsIfNeeded(state: &state)
		}
	}

	private func validate(
		_ olympiaDevice: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice,
		againstUnverifiedOf state: inout State
	) -> EffectTask<Action> {
		guard !olympiaDevice.derivedPublicKeys.isEmpty else {
			loggerGlobal.warning("Response contained no public keys at all.")
			return .none
		}
		do {
			let derivedKeys = try Set(
				olympiaDevice
					.derivedPublicKeys
					.map { try K1.PublicKey(compressedRepresentation: $0.publicKey.data) }
			)

			let olympiaAccountsToMigrate = state.unverified.filter {
				derivedKeys.contains($0.publicKey)
			}

			if olympiaAccountsToMigrate.isEmpty, !state.unverified.isEmpty, !olympiaDevice.derivedPublicKeys.isEmpty {
				loggerGlobal.critical("Invalid keys from export format?\nolympiaDevice.derivedPublicKeys: \(olympiaDevice.derivedPublicKeys.map { $0.publicKey.data.hex() })\nstate.unverified:\(state.unverified.map(\.publicKey.compressedRepresentation.hex))")
			}

			guard let verifiedToBeMigrated = NonEmpty<OrderedSet<OlympiaAccountToMigrate>>.init(rawValue: OrderedSet(uncheckedUniqueElements: olympiaAccountsToMigrate.sorted(by: \.addressIndex))) else {
				loggerGlobal.warning("No accounts to migrated.")
				return .none
			}
			loggerGlobal.notice("Prompting to name ledger with ID=\(olympiaDevice.id) before migrating #\(verifiedToBeMigrated.count) accounts.")
			state.verifiedToBeMigrated = verifiedToBeMigrated

			olympiaAccountsToMigrate.forEach { verifiedAccountToMigrate in
				state.unverified.remove(verifiedAccountToMigrate)
			}

			return .send(.internal(
				.nameLedgerDeviceBeforeSavingIt(olympiaDevice)
			))

		} catch {
			loggerGlobal.error("got error: \(error)")
			return .none
		}
	}

	private func addFactorSource(
		name: String?,
		unnamedDeviceToAdd device: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice
	) -> EffectTask<Action> {
		let model = FactorSource.LedgerHardwareWallet.DeviceModel(model: device.model)

		loggerGlobal.notice("Creating factor source for Ledger...")

		let factorSource = FactorSource.ledger(
			id: device.id,
			model: model,
			name: name,
			olympiaCompatible: true
		)

		loggerGlobal.notice("Created factor source for Ledger! adding it now")

		return .run { send in
			try await factorSourcesClient.addOffDeviceFactorSource(factorSource)
			loggerGlobal.notice("Added Ledger factor source! ✅ ")
			await send(.internal(.addedFactorSource(factorSource, model, name: name)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to add Factor Source, error: \(error)")
			errorQueue.schedule(error)
		}
	}

	private func convertHardwareAccountsToBabylon(
		_ olympiaAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
		factorSource: FactorSource,
		model: FactorSource.LedgerHardwareWallet.DeviceModel,
		ledgerName: String?
	) -> EffectTask<Action> {
		.run { send in
			// Migrates and saved all accounts to Profile
			let migrated = try await importLegacyWalletClient.migrateOlympiaHardwareAccountsToBabylon(
				.init(
					olympiaAccounts: Set(olympiaAccounts.elements),
					ledgerFactorSourceID: factorSource.id
				)
			)
			loggerGlobal.notice("Converted #\(migrated.babylonAccounts.count) accounts to babylon! ✅")
			let addedLedgerWithAccounts = AddedLedgerWithAccounts(
				name: ledgerName,
				model: model,
				id: factorSource.id,
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
				addedLedgersWithAccounts: state.addedLedgersWithAccounts,
				unvalidatedAccounts: []
			)))
		} else {
			loggerGlobal.notice("state.unverified not empty #\(state.unverified.count) unverfied remain, preparing to send importOlympiaDevice request...")
			state.isWaitingForResponseFromLedger = true
			return .run { [olympiaAccounts = state.unverified] send in
				let device = try await ledgerHardwareWalletClient.importOlympiaDevice(olympiaAccounts)
				await send(.internal(.validateLedgerBeforeNamingIt(device)))
			} catch: { error, send in
				loggerGlobal.error("Failed to import olympia ledger device, error: \(error)")
				await send(.internal(.failedToImportOlympiaLedger))
			}
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
