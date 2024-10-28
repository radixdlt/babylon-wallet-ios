// MARK: - PreAuthorizationReview
struct PreAuthorizationReview: Sendable, FeatureReducer {
	typealias Common = InteractionReview
	typealias Expiration = DappToWalletInteractionSubintentExpiration

	struct State: Sendable, Hashable {
		let unvalidatedManifest: UnvalidatedTransactionManifest
		let expiration: Expiration?
		let nonce: Nonce
		let signTransactionPurpose: SigningPurpose.SignTransactionPurpose
		let dAppMetadata: DappMetadata.Ledger?

		var reviewedPreAuthorization: ReviewedPreAuthorization?

		var displayMode: Common.DisplayMode = .detailed
		var sliderResetDate: Date = .now // TODO: reset when it corresponds
		var secondsToExpiration: Int?

		// Sections
		var sections: Common.Sections.State = .init(kind: .preAuthorization)
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case toggleDisplayModeButtonTapped
		case copyRawTransactionButtonTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case sections(Common.Sections.Action)
	}

	enum InternalAction: Sendable, Equatable {
		case previewLoaded(TaskResult<PreAuthorizationToReview>)
		case updateSecondsToExpiration(Date)
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.preAuthorizationClient) var preAuthorizationClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Scope(state: \.sections, action: \.child.sections) {
			Common.Sections()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .run { [state = state] send in
				let preview = await TaskResult {
					try await preAuthorizationClient.getPreview(.init(
						unvalidatedManifest: state.unvalidatedManifest,
						nonce: state.nonce
					))
				}
				await send(.internal(.previewLoaded(preview)))
			}

		case .toggleDisplayModeButtonTapped:
			switch state.displayMode {
			case .detailed:
				return showRawTransaction(&state)
			case .raw:
				state.displayMode = .detailed
				return .none
			}

		case .copyRawTransactionButtonTapped:
			guard let manifest = state.displayMode.rawTransaction else {
				assertionFailure("Copy raw manifest button should only be visible in raw transaction mode")
				return .none
			}
			pasteboardClient.copyString(manifest)
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .previewLoaded(.failure(error)):
			loggerGlobal.error("PreAuthroization preview failed, error: \(error)")
			errorQueue.schedule(error)
			return .none

		case let .previewLoaded(.success(preview)):
			state.reviewedPreAuthorization = .init(manifest: preview.manifest)

			var effects: [Effect<Action>] = []

			// Trigger effect to load sections
			let sectionsEffect: Effect<Action> = switch preview.kind {
			case let .open(value):
				.send(.child(.sections(.internal(.parent(.resolveManifestSummary(value.summary, preview.networkID))))))
			case let .enclosed(value):
				.send(.child(.sections(.internal(.parent(.resolveExecutionSummary(value.summary, preview.networkID))))))
			}
			effects.append(sectionsEffect)

			switch state.expiration {
			case let .atTime(value):
				// Trigger expiration countdown effect
				let expirationDate = value.unixTimestampSeconds
				state.secondsToExpiration = Int(expirationDate.timeIntervalSinceNow)
				effects.append(startTimer(expirationDate: expirationDate))
			case .afterDelay, .none:
				break
			}

			return .merge(effects)

		case let .updateSecondsToExpiration(expiration):
			state.secondsToExpiration = Int(expiration.timeIntervalSinceNow)
			return .none
		}
	}
}

private extension PreAuthorizationReview {
	func startTimer(expirationDate: Date) -> Effect<Action> {
		.run { send in
			for await _ in self.clock.timer(interval: .seconds(1)) {
				await send(.internal(.updateSecondsToExpiration(expirationDate)))
			}
		}
		.cancellable(id: CancellableId.expirationTimer, cancelInFlight: true)
	}

	func showRawTransaction(_ state: inout State) -> Effect<Action> {
		guard let reviewedTransaction = state.reviewedPreAuthorization else {
			struct MissingReviewedPreAuthorization: Error {}
			errorQueue.schedule(MissingReviewedPreAuthorization())
			return .none
		}
		// TODO: Confirm if we shouldn't expose manifest.instructionsString
		state.displayMode = .raw(reviewedTransaction.manifest.manifestString)
		return .none
	}
}

extension PreAuthorizationReview {
	private enum CancellableId: Hashable {
		case expirationTimer
	}

	struct ReviewedPreAuthorization: Sendable, Hashable {
		let manifest: SubintentManifest
	}
}

extension PreAuthorizationReview.State {
	var isExpired: Bool {
		switch expiration {
		case let .atTime(value):
			value.unixTimestampSeconds <= Date.now
		case .afterDelay, .none:
			false
		}
	}
}
