// MARK: - PreAuthorizationReview.PollingStatus
extension PreAuthorizationReview {
	struct PollingStatus: Sendable, FeatureReducer {
		struct State: Sendable, Hashable {
			let dAppMetadata: DappMetadata
			let subintentHash: SubintentHash
			let expiration: Expiration
			let isDeepLink: Bool
			let request: RequestEnvelope
			var status = Status.unknown
			var secondsToExpiration: Int

			init(config: Config, request: RequestEnvelope) {
				self.dAppMetadata = config.dAppMetadata
				self.subintentHash = config.subintentHash
				self.expiration = config.expiration
				self.isDeepLink = config.isDeepLink
				self.request = request
				switch expiration {
				case let .afterDelay(afterDelay):
					secondsToExpiration = Int(afterDelay.expireAfterSeconds)
				case let .atTime(atTime):
					secondsToExpiration = Int(atTime.date.timeIntervalSinceNow)
				}
			}
		}

		enum ViewAction: Sendable, Equatable {
			case onFirstTask
			case closeButtonTapped
		}

		enum InternalAction: Sendable, Equatable {
			case setStatus(PreAuthorizationStatus)
			case updateSecondsToExpiration
		}

		enum DelegateAction: Sendable, Equatable {
			case committedSuccessfully(TransactionIntentHash, DappMetadata, RequestEnvelope)
			case dismiss
		}

		@Dependency(\.preAuthorizationClient) var preAuthorizationClient
		@Dependency(\.continuousClock) var clock

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .onFirstTask:
				pollStatus(state: &state)
					.merge(with: startTimer())
			case .closeButtonTapped:
				.send(.delegate(.dismiss))
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .setStatus(status):
				var effects: [Effect<Action>] = [.cancel(id: CancellableId.expirationTimer)]
				switch status {
				case .expired:
					state.status = .expired
				case let .success(intentHash):
					effects.append(.send(.delegate(.committedSuccessfully(intentHash, state.dAppMetadata, state.request))))
				}
				return .merge(effects)

			case .updateSecondsToExpiration:
				state.secondsToExpiration -= 1
				return .none
			}
		}

		private func pollStatus(state: inout State) -> Effect<Action> {
			let request = PreAuthorizationClient.PollStatusRequest(
				subintentHash: state.subintentHash,
				expiration: state.expiration
			)
			return .run { send in
				let status = try await preAuthorizationClient.pollStatus(request)
				await send(.internal(.setStatus(status)))
			}
		}

		private func startTimer() -> Effect<Action> {
			.run { send in
				for await _ in self.clock.timer(interval: .seconds(1)) {
					await send(.internal(.updateSecondsToExpiration))
				}
			}
			.cancellable(id: CancellableId.expirationTimer, cancelInFlight: true)
		}
	}
}

extension PreAuthorizationReview.PollingStatus {
	struct Config: Sendable, Equatable {
		let dAppMetadata: DappMetadata
		let subintentHash: SubintentHash
		let expiration: DappToWalletInteractionSubintentExpiration
		let isDeepLink: Bool
	}

	enum Status: Sendable, Hashable {
		/// The Pre-Authorization hasn't been submitted within a Transaction yet. We are still polling until we get a final status (success or expired).
		case unknown

		/// The Pre-Authorization wasn't committed successfully within a Transaction and it has now expired.
		case expired
	}

	private enum CancellableId: Hashable {
		case expirationTimer
	}
}
