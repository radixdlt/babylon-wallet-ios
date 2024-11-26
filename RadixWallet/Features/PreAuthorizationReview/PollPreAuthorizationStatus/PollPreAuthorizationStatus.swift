// MARK: - PollPreAuthorizationStatus
struct PollPreAuthorizationStatus: Sendable, FeatureReducer {
	typealias Expiration = DappToWalletInteractionSubintentExpiration

	struct State: Sendable, Hashable {
		let dAppMetadata: DappMetadata
		let subintentHash: SubintentHash
		let expiration: Expiration
		let isDeepLink: Bool
		let request: RequestEnvelope
		var status = Status.unknown
		var secondsToExpiration: Int

		init(
			dAppMetadata: DappMetadata,
			subintentHash: SubintentHash,
			expiration: Expiration,
			isDeepLink: Bool,
			request: RequestEnvelope
		) {
			self.dAppMetadata = dAppMetadata
			self.subintentHash = subintentHash
			self.expiration = expiration
			self.isDeepLink = isDeepLink
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
			switch status {
			case .expired:
				state.status = .expired
				return .cancel(id: CancellableId.expirationTimer)
			case let .success(intentHash):
				return .cancel(id: CancellableId.expirationTimer)
					.merge(with: .send(.delegate(.committedSuccessfully(intentHash, state.dAppMetadata, state.request))))
			}

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

extension PollPreAuthorizationStatus {
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
