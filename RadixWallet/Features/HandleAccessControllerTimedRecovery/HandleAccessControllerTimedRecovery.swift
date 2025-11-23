import SargonUniFFI

// MARK: - HandleAccessControllerTimedRecovery
@Reducer
struct HandleAccessControllerTimedRecovery: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let acDetails: AccessControllerStateDetails
		let provisionalSecurityState: SecurityStructureOfFactorSources?
		let entity: AccountOrPersona
		var isSecurityStructureExpanded: Bool = false

		init(acDetails: AccessControllerStateDetails) throws {
			self.acDetails = acDetails
			entity = try SargonOs.shared.entityByAccessControllerAddress(address: acDetails.address)
			provisionalSecurityState = try? SargonOs.shared.provisionalSecurityStructureOfFactorSourcesFromAddressOfAccountOrPersona(addressOfAccountOrPersona: entity.address)
		}

		/// Whether this recovery was initiated through this wallet (has provisional state)
		var isKnownRecovery: Bool {
			provisionalSecurityState != nil
		}

		/// The timed recovery state from the access controller
		var timedRecoveryState: TimedRecoveryState? {
			acDetails.timedRecoveryState
		}

		/// The unix timestamp (in seconds) when recovery can be confirmed
		var recoveryTimestampSeconds: UInt64? {
			timedRecoveryState.flatMap { UInt64($0.allowTimedRecoveryAfterUnixTimestampSeconds) }
		}

		/// The date when recovery can be confirmed
		var recoveryConfirmationDate: Date? {
			guard let timestamp = recoveryTimestampSeconds else { return nil }
			return Date(timeIntervalSince1970: TimeInterval(timestamp))
		}

		/// Whether the waiting period has expired and recovery can be confirmed
		var isRecoveryConfirmable: Bool {
			guard let confirmationDate = recoveryConfirmationDate else { return false }
			return Date.now >= confirmationDate
		}

		/// Time remaining until recovery can be confirmed (nil if already confirmable)
		var timeUntilRecoverable: TimeInterval? {
			guard let confirmationDate = recoveryConfirmationDate else { return nil }
			let remaining = confirmationDate.timeIntervalSince(Date.now)
			return remaining > 0 ? remaining : nil
		}

		/// Formatted date string for when recovery can be confirmed
		var formattedConfirmationDate: String? {
			guard let date = recoveryConfirmationDate else { return nil }
			return date.formatted(.dateTime.day().month(.wide).year().hour().minute())
		}

		/// Formatted countdown string (e.g., "2 days, 5 hours, 30 minutes")
		var formattedCountdown: String? {
			guard let timeRemaining = timeUntilRecoverable else { return nil }

			let days = Int(timeRemaining) / 86400
			let hours = (Int(timeRemaining) % 86400) / 3600
			let minutes = (Int(timeRemaining) % 3600) / 60

			var components: [String] = []
			if days > 0 {
				components.append("\(days) day\(days == 1 ? "" : "s")")
			}
			if hours > 0 {
				components.append("\(hours) hour\(hours == 1 ? "" : "s")")
			}
			if minutes > 0 || components.isEmpty {
				components.append("\(minutes) minute\(minutes == 1 ? "" : "s")")
			}

			return components.joined(separator: ", ")
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case appeared
		case stopButtonTapped
		case confirmButtonTapped
		case securityStructureToggled
	}

	@Dependency(\.dappInteractionClient) var dappInteractionClient
	@Dependency(\.submitTXClient) var submitTXClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .securityStructureToggled:
			state.isSecurityStructureExpanded.toggle()
			return .none
		case .stopButtonTapped:
			return .run { [entityAddress = state.entity.address] _ in
				let manifest = try await SargonOS.shared.makeStopTimedRecoveryManifest(address: entityAddress)
				Task {
					let result = await dappInteractionClient.addWalletInteraction(
						.transaction(.init(send: .init(transactionManifest: manifest))),
						.shieldUpdate
					)

					switch result.p2pResponse {
					case let .dapp(.success(success)):
						if case let .transaction(tx) = success.items {
							/// Wait for the transaction to be committed
							let txID = tx.send.transactionIntentHash
							if try await submitTXClient.hasTXBeenCommittedSuccessfully(txID) {
								// TODO: Use a client which wraps SargonOS so this features becomes testable
								try await SargonOs.shared.removeProvisionalSecurityState(entityAddress: entityAddress)
							}
							return
						}

						assertionFailure("Not a transaction Response?")
					case .dapp(.failure):
						break
					}
				}
			}
		case .confirmButtonTapped:
			return .run { [entityAddress = state.entity.address] _ in
				let manifest = try await SargonOS.shared.makeConfirmTimedRecoveryManifest(address: entityAddress)
				Task {
					let result = await dappInteractionClient.addWalletInteraction(
						.transaction(.init(send: .init(transactionManifest: manifest))),
						.shieldUpdate
					)

					switch result.p2pResponse {
					case let .dapp(.success(success)):
						if case let .transaction(tx) = success.items {
							/// Wait for the transaction to be committed
							let txID = tx.send.transactionIntentHash
							if try await submitTXClient.hasTXBeenCommittedSuccessfully(txID) {
								// TODO: Use a client which wraps SargonOS so this features becomes testable
								try await SargonOs.shared.commitProvisionalSecurityState(entityAddress: entityAddress)
							}
							return
						}

						assertionFailure("Not a transaction Response?")
					case .dapp(.failure):
						break
					}
				}
			}
		}
	}
}
