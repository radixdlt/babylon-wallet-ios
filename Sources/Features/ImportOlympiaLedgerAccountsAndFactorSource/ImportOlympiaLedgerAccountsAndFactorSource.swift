import Cryptography
import FactorSourcesClient
import FeaturePrelude
import ImportLegacyWalletClient
import Profile
import RadixConnectClient
import SharedModels

// MARK: - ImportOlympiaLedgerAccountsAndFactorSource
public struct ImportOlympiaLedgerAccountsAndFactorSource: Sendable, FeatureReducer {
	public struct AddedLedgerWithAccounts: Sendable, Hashable {
		public let name: String?
		public let model: FactorSource.LedgerHardwareWallet.DeviceModel
		public let id: FactorSource.ID
		public let migratedAccounts: NonEmpty<OrderedSet<MigratedAccount>>
	}

	public struct State: Sendable, Hashable {
		public var outgoingInteractionIDs: Set<P2P.LedgerHardwareWallet.InteractionId>?

		/// unverified, to verify and migrate
		public var unverified: Set<OlympiaAccountToMigrate>

		/// verified but not yet migrated, to be migrated/converted
		public var verifiedToBeMigrated: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>?

		/// verified and migrated
		public var addedLedgersWithAccounts: OrderedSet<AddedLedgerWithAccounts> = []

		public var ledgerName = ""
		public var isLedgerNameInputVisible = false
		public var unnamedDeviceToAdd: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice?

		public init(
			hardwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		) {
			precondition(hardwareAccounts.allSatisfy { $0.accountType == .hardware })
			self.unverified = Set(hardwareAccounts.elements)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case sendAddLedgerRequestButtonTapped
		case skipRestOfTheAccounts
		case ledgerNameChanged(String)
		case confirmNameButtonTapped
		case skipNamingLedgerButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case response(
			olympiaDevice: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice,
			interactionID: P2P.LedgerHardwareWallet.InteractionId
		)
		case broadcasted(interactionID: P2P.LedgerHardwareWallet.InteractionId)

		case nameLedgerDeviceBeforeSavingIt(
			P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice
		)

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

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .fireAndForget {
				await radixConnectClient.loadFromProfileAndConnectAll()
			}
		case .sendAddLedgerRequestButtonTapped:
			return continueWithRestOfAccountsIfNeeded(state: state)

		case .skipRestOfTheAccounts:
			return .send(.delegate(.completed(
				addedLedgersWithAccounts: state.addedLedgersWithAccounts,
				unvalidatedAccounts: state.unverified
			)))

		case let .ledgerNameChanged(name):
			state.ledgerName = name
			return .none

		case .confirmNameButtonTapped:
			guard let device = state.unnamedDeviceToAdd else {
				assertionFailure("Expected device to name")
				return .none
			}
			return addFactorSource(
				name: nil,
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
		case let .response(olympiaDevice, interactionID):
			return validate(olympiaDevice, againstUnverifiedOf: &state)
		case let .broadcasted(interactionID):
			return .none

		case let .nameLedgerDeviceBeforeSavingIt(device):
			state.unnamedDeviceToAdd = device
			state.isLedgerNameInputVisible = true
			return .none

		case let .addedFactorSource(factorSource, model, name):
			state.unnamedDeviceToAdd = nil
			state.isLedgerNameInputVisible = false
			state.ledgerName = ""
			guard let verifiedToMigrate = state.verifiedToBeMigrated else {
				assertionFailure("Expected verified accounts to migrated")
				return .none
			}
			return convertHardwareAccountsToBabylon(
				verifiedToMigrate,
				factorSource: factorSource,
				model: model,
				ledgerName: name
			)

		case let .migratedOlympiaHardwareAccounts(addedLedgerWithAccounts):
			state.addedLedgersWithAccounts.append(addedLedgerWithAccounts)
			state.verifiedToBeMigrated = nil

			return continueWithRestOfAccountsIfNeeded(state: state)
		}
	}

	private func listenForResponses(
		interactionID: P2P.LedgerHardwareWallet.InteractionId
	) -> EffectTask<Action> {
		.run { send in
			for try await incomingResponse in await radixConnectClient.receiveResponses(/P2P.RTCMessageFromPeer.Response.connectorExtension .. /P2P.ConnectorExtension.Response.ledgerHardwareWallet) {
				guard !Task.isCancelled else {
					return
				}

				let response = try incomingResponse.result.get()

				switch response.response {
				case let .success(.importOlympiaDevice(olympiaDevice)):
					await send(.internal(
						.response(
							olympiaDevice: olympiaDevice,
							interactionID: response.interactionID
						)
					))
				case let .failure(errorFromConnectorExtension):
					throw errorFromConnectorExtension
				default: break
				}
			}
		} catch: { error, _ in
			errorQueue.schedule(error)
			//            await send(.internal(.failure(interactionID: interactionID)))
			loggerGlobal.error("Fail interactionID: \(interactionID), error: \(error)")
		}
	}

	private func importOlympiaDevice(
		interactionID: P2P.LedgerHardwareWallet.InteractionId,
		olympiaHardwareAccounts: Set<OlympiaAccountToMigrate>
	) -> EffectTask<Action> {
		.run { send in

			let request: P2P.ConnectorExtension.Request.LedgerHardwareWallet.Request.ImportOlympiaDevice = .init(
				derivationPaths: olympiaHardwareAccounts.map(\.path.derivationPath)
			)

			try await radixConnectClient.sendRequest(.connectorExtension(.ledgerHardwareWallet(.init(
				interactionID: interactionID,
				request: .importOlympiaDevice(request)
			))), .broadcastToAllPeers)

			await send(.internal(.broadcasted(interactionID: interactionID)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to send message to Connector Extension, error: \(error)")
		}
	}

	private func validate(
		_ olympiaDevice: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice,
		againstUnverifiedOf state: inout State
	) -> EffectTask<Action> {
		do {
			let derivedKeys = try Set(
				olympiaDevice
					.derivedPublicKeys
					.map { try K1.PublicKey(compressedRepresentation: $0.publicKey.data) }
			)

			let olympiaAccountsToMigrate = state.unverified.filter {
				derivedKeys.contains($0.publicKey)
			}

			olympiaAccountsToMigrate.forEach { verifiedAccountToMigrate in
				state.unverified.remove(verifiedAccountToMigrate)
			}

			state.verifiedToBeMigrated = .init(rawValue: OrderedSet(uncheckedUniqueElements: olympiaAccountsToMigrate.sorted(by: \.addressIndex)))

			return .send(.internal(
				.nameLedgerDeviceBeforeSavingIt(olympiaDevice)
			))

		} catch {
			fatalError()
		}
	}

	private func addFactorSource(
		name: String?,
		unnamedDeviceToAdd device: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice
	) -> EffectTask<Action> {
		let model = FactorSource.LedgerHardwareWallet.DeviceModel(model: device.model)
		let factorSource = FactorSource.ledger(
			id: device.id,
			model: model,
			name: name.map { NonEmpty(rawValue: $0) } ?? nil,
			olympiaCompatible: true
		)
		return .run { send in
			try await factorSourcesClient.addOffDeviceFactorSource(factorSource)
			await send(.internal(.addedFactorSource(factorSource, model, name: name)))
		} catch: { _, _ in
			fatalError()
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
			let addedLedgerWithAccounts = AddedLedgerWithAccounts(
				name: ledgerName,
				model: model,
				id: factorSource.id,
				migratedAccounts: migrated.accounts
			)

			await send(.internal(.migratedOlympiaHardwareAccounts(addedLedgerWithAccounts)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	private func continueWithRestOfAccountsIfNeeded(state: State) -> EffectTask<Action> {
		if state.unverified.isEmpty {
			return .send(.delegate(.completed(
				addedLedgersWithAccounts: state.addedLedgersWithAccounts,
				unvalidatedAccounts: []
			)))
		} else {
			let interactionId: P2P.LedgerHardwareWallet.InteractionId = .random()
			return importOlympiaDevice(
				interactionID: interactionId,
				olympiaHardwareAccounts: state.unverified
			).concatenate(with: listenForResponses(interactionID: interactionId))
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
