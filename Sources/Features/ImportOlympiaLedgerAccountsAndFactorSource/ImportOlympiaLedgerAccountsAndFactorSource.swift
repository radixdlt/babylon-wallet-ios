import Cryptography
import FactorSourcesClient
import FeaturePrelude
import ImportLegacyWalletClient
import Profile
import RadixConnectClient
import SharedModels

// MARK: - ImportOlympiaLedgerAccountsAndFactorSource
public struct ImportOlympiaLedgerAccountsAndFactorSource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var outgoingInteractionIDs: Set<P2P.LedgerHardwareWallet.InteractionId>?

		/// unverified, to verify and migrate
		public var unverified: Set<OlympiaAccountToMigrate>

		/// verified but not yet migrated
		public var verified: Set<OlympiaAccountToMigrate> = []

		/// verified and migrated
		public var migrated: OrderedSet<MigratedAccount> = []

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
			P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice,
			verifiedAccountsToMigrate: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		)

		case addedFactorSource(FactorSource)

		case migratedOlympiaHardwareAccounts(
			NonEmpty<OrderedSet<MigratedAccount>>,
			FactorSource
		)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(
			validatatedAccounts: Set<OlympiaAccountToMigrate>,
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
			let interactionId: P2P.LedgerHardwareWallet.InteractionId = .random()
			return importOlympiaDevice(
				interactionID: interactionId,
				olympiaHardwareAccounts: state.unverified
			).concatenate(with: listenForResponses(interactionID: interactionId))

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

		case let .nameLedgerDeviceBeforeSavingIt(device, verifiedOlympiaAccounts):
			state.unnamedDeviceToAdd = device
			state.isLedgerNameInputVisible = true
			return .none

		case let .addedFactorSource(factorSource):
			state.unnamedDeviceToAdd = nil
			state.isLedgerNameInputVisible = false
			state.ledgerName = ""
			return convertHardwareAccountsToBabylon(state.verified, factorSource: factorSource)

		case let .migratedOlympiaHardwareAccounts(migratedAccounts, olympiaDevice):
			state.migrated.append(contentsOf: migratedAccounts.rawValue)
//			return nameLedgerDeviceBeforeSavingIt(olympiaDevice, controlling: migratedAccounts)
			fatalError()
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
				state.verified.insert(verifiedAccountToMigrate)
				state.unverified.remove(verifiedAccountToMigrate)
			}

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
		let factorSource = FactorSource.ledger(
			id: device.id,
			model: device.model,
			name: name.map { NonEmpty(rawValue: $0) },
			olympiaCompatible: true
		)
		return .run { send in
			try await factorSourcesClient.addOffDeviceFactorSource(factorSource)
			await send(.internal(.addedFactorSource(factorSource)))
		} catch: { _, _ in
			fatalError()
		}
	}

	private func convertHardwareAccountsToBabylon(
		_ olympiaAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
		factorSource: FactorSource
	) -> EffectTask<Action> {
		.run { send in
			// Migrates and saved all accounts to Profile
			let migrated = try await importLegacyWalletClient.migrateOlympiaHardwareAccountsToBabylon(
				.init(
					olympiaAccounts: Set(olympiaAccounts.elements),
					ledgerFactorSourceID: factorSource.id
				)
			)
			await send(.internal(.migratedOlympiaHardwareAccounts(migrated.accounts, factorSource)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}
