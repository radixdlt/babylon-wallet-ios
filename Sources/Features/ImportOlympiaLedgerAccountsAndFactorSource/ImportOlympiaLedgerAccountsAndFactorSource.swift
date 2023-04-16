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

		@PresentationState
		public var nameLedgerAlert: AlertState<ViewAction.NameLedgerAlert>? = nil

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
		case nameLedgerAlert(PresentationAction<NameLedgerAlert>)

		public enum NameLedgerAlert: Sendable, Equatable {
			case confirmNameButtonTapped
			case skipNameButtonTapped
		}
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

		case migratedOlympiaHardwareAccounts(
			NonEmpty<OrderedSet<MigratedAccount>>,
			P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice
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

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)

			.ifLet(\.$nameLedgerAlert, action: /Action.view .. ViewAction.nameLedgerAlert)
	}

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

		case .nameLedgerAlert(.presented(.confirmNameButtonTapped)):
//			return disconnectDappEffect(state: state)
			fatalError()

		case .nameLedgerAlert:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .response(olympiaDevice, interactionID):
			return validate(olympiaDevice, againstUnverifiedOf: &state)
		case let .broadcasted(interactionID):
			return .none

		case let .nameLedgerDeviceBeforeSavingIt(device, verifiedOlympiaAccounts):
			state.nameLedgerAlert = .nameLedger(device, verifiedOlympiaAccounts)

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
			let derivedKeys = try Set(olympiaDevice.derivedPublicKeys.map { try K1.PublicKey(compressedRepresentation: $0.publicKey.data) })
			let olympiaAccountsToMigrate = state.unverified.filter {
				derivedKeys.contains($0.publicKey)
			}
			var verifiedAccountsToMigrate = OrderedSet<OlympiaAccountToMigrate>()
			olympiaAccountsToMigrate.forEach { verifiedAccountToMigrate in
//				let verifiedAccountToMigrate: OlympiaAccountToMigrate = {
//					state.unverified.first(where: { $0.publicKey == verifiedKey })!
//				}()
				verifiedAccountsToMigrate.append(verifiedAccountToMigrate)
				state.verified.insert(verifiedAccountToMigrate)
				state.unverified.remove(verifiedAccountToMigrate)
			}

			let nonEmpty = NonEmpty(rawValue: verifiedAccountsToMigrate)!
//			return send(.internal(.nameLedgerDeviceBeforeSavingIt(olympiaDevice, verifiedAccountsToMigrate: nonEmpty)))
			return EffectTask<Action>.send(.internal(.nameLedgerDeviceBeforeSavingIt(olympiaDevice, verifiedAccountsToMigrate: nonEmpty)))
		} catch {
			fatalError()
		}
//		return convertHardwareAccountsToBabylon(olympiaAccountsToMigrate, device: olympiaDevice)
	}

	private func convertHardwareAccountsToBabylon(
		_ olympiaAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
		device: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice
	) -> EffectTask<Action> {
		.run { send in
			// Migrates and saved all accounts to Profile
			let migrated = try await importLegacyWalletClient.migrateOlympiaHardwareAccountsToBabylon(
				.init(
					olympiaAccounts: Set(olympiaAccounts.elements),
					ledgerFactorSourceID: ledgerNanoFactorSourceID
				)
			)
			await send(.internal(.migratedOlympiaHardwareAccounts(migrated, olympiaDevice)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}

extension AlertState<ImportOlympiaLedgerAccountsAndFactorSource.ViewAction.NameLedgerAlert> {
	static func nameLedger(
		_ device: P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.ImportOlympiaDevice,
		verifiedAccountsToMigrate: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	)
		-> AlertState
	{
		AlertState {
			TextState(L10n.DAppDetails.forgetDappAlertTitle)
		} actions: {
			ButtonState(role: .destructive, action: .confirmTapped) {
				TextState(L10n.DAppDetails.forgetDappAlertConfirm)
			}
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.DAppDetails.forgetDappAlertCancel)
			}
		} message: {
			TextState(L10n.DAppDetails.forgetDappAlertMessage)
		}
	}
}
