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
		var secondsUntilRecoverable: Int

		init(acDetails: AccessControllerStateDetails) throws {
			self.acDetails = acDetails
			entity = try SargonOs.shared.entityByAccessControllerAddress(address: acDetails.address)
			provisionalSecurityState = try? SargonOs.shared.provisionalSecurityStructureOfFactorSourcesFromAddressOfAccountOrPersona(addressOfAccountOrPersona: entity.address)

			// Calculate initial seconds until recoverable
			if let timestamp = acDetails.timedRecoveryState.flatMap({ UInt64($0.allowTimedRecoveryAfterUnixTimestampSeconds) }) {
				let confirmationDate = Date(timeIntervalSince1970: TimeInterval(timestamp))
				let remaining = confirmationDate.timeIntervalSince(Date.now)
				self.secondsUntilRecoverable = max(0, Int(remaining))
			} else {
				self.secondsUntilRecoverable = 0
			}
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
			secondsUntilRecoverable <= 0
		}

		/// Formatted date string for when recovery can be confirmed
		var formattedConfirmationDate: String? {
			guard let date = recoveryConfirmationDate else { return nil }
			return date.formatted(.dateTime.day().month(.wide).year().hour().minute())
		}

		/// Formatted countdown string using the same format as PreAuthorizationReview
		var formattedCountdown: String? {
			guard secondsUntilRecoverable > 0 else { return nil }
			return PreAuthorizationReview.TimeFormatter.format(seconds: secondsUntilRecoverable)
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case appeared
		case stopButtonTapped
		case confirmButtonTapped
		case securityStructureToggled
	}

	enum InternalAction: Sendable, Equatable {
		case timerTicked
	}

	@Dependency(\.dappInteractionClient) var dappInteractionClient
	@Dependency(\.submitTXClient) var submitTXClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.accessControllerClient) var accessControllerClient

	enum CancelID: Hashable {
		case timer
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			// Start a timer to update the countdown and button state
			guard state.secondsUntilRecoverable > 0 else {
				// Already confirmable, no need for timer
				return .none
			}
			return .run { send in
				for await _ in clock.timer(interval: .seconds(1)) {
					await send(.internal(.timerTicked))
				}
			}
			.cancellable(id: CancelID.timer)
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
								// Force refresh access controller state after successful stop transaction
								await accessControllerClient.forceRefresh()
							}
							return
						}

						assertionFailure("Not a transaction Response?")
					case .dapp(.failure):
						break
					}
				}
				await dismiss()
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
								// Force refresh access controller state after successful confirm transaction
								await accessControllerClient.forceRefresh()
							}
							return
						}

						assertionFailure("Not a transaction Response?")
					case .dapp(.failure):
						break
					}
				}
				await dismiss()
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .timerTicked:
			// Decrement the countdown
			state.secondsUntilRecoverable -= 1

			// Cancel timer if recovery is now confirmable
			if state.secondsUntilRecoverable <= 0 {
				return .cancel(id: CancelID.timer)
			}
			return .none
		}
	}
}
