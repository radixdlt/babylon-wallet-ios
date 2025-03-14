// MARK: - PreAuthorizationReview
struct PreAuthorizationReview: Sendable, FeatureReducer {
	typealias Common = InteractionReview
	typealias Expiration = DappToWalletInteractionSubintentExpiration

	struct State: Sendable, Hashable {
		let unvalidatedManifest: UnvalidatedSubintentManifest
		let expiration: Expiration
		let nonce: Nonce
		let ephemeralNotaryPrivateKey: Curve25519.Signing.PrivateKey = .init()
		let dAppMetadata: DappMetadata
		let message: String?

		var preview: PreAuthorizationPreview?

		var displayMode: Common.DisplayMode = .detailed
		var isApprovalInProgress: Bool = false
		var sliderResetDate: Date = .now
		var secondsToExpiration: Int?

		// Sections
		var sections: Common.Sections.State = .init(kind: .preAuthorization)

		@PresentationState
		var destination: Destination.State? = nil
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case toggleDisplayModeButtonTapped
		case approvalSliderSlid
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case sections(Common.Sections.Action)
	}

	enum InternalAction: Sendable, Equatable {
		case previewLoaded(TaskResult<PreAuthorizationPreview>)
		case builtSubintent(Subintent)
		case updateSecondsToExpiration(Date)
		case resetToApprovable
	}

	enum DelegateAction: Sendable, Equatable {
		case signedPreAuthorization(SignedSubintent)
		case failed(TransactionFailure)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case rawManifestAlert(AlertState<Never>)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case rawManifestAlert(Never)
		}

		var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.preAuthorizationClient) var preAuthorizationClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Scope(state: \.sections, action: \.child.sections) {
			Common.Sections()
		}
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .run { [state = state] send in
				let preview = await TaskResult {
					try await preAuthorizationClient.getPreview(.init(
						unvalidatedManifest: state.unvalidatedManifest,
						nonce: state.nonce,
						notaryPublicKey: state.ephemeralNotaryPrivateKey.publicKey
					))
				}
				await send(.internal(.previewLoaded(preview)))
			}

		case .toggleDisplayModeButtonTapped:
			switch state.displayMode {
			case .detailed:
				return showRawManifest(&state)
			case .raw:
				state.displayMode = .detailed
				return .none
			}

		case .approvalSliderSlid:
			state.isApprovalInProgress = true
			return buildSubintent(state: state)
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .previewLoaded(.failure(error)):
			loggerGlobal.error("PreAuthroization preview failed, error: \(error)")
			errorQueue.schedule(TransactionReviewFailure(underylying: error))
			if let txFailure = error as? TransactionFailure {
				return .send(.delegate(.failed(txFailure)))
			} else {
				return .send(.delegate(.failed(TransactionFailure.failedToPrepareTXReview(.abortedTXReview(error)))))
			}

		case let .previewLoaded(.success(preview)):
			state.preview = preview

			var effects: [Effect<Action>] = []

			// Trigger effect to load sections
			let sectionsEffect: Effect<Action> = switch preview.kind {
			case let .open(value):
				.send(.child(.sections(.internal(.parent(.resolveManifestSummary(value.summary, preview.networkId))))))
			case let .enclosed(value):
				.send(.child(.sections(.internal(.parent(.resolveExecutionSummary(value.summary, preview.networkId))))))
			}
			effects.append(sectionsEffect)

			switch state.expiration {
			case let .atTime(value):
				// Trigger expiration countdown effect
				let expirationDate = value.date
				state.secondsToExpiration = Int(expirationDate.timeIntervalSinceNow)
				effects.append(startTimer(expirationDate: expirationDate))
			case .afterDelay:
				break
			}

			return .merge(effects)

		case let .builtSubintent(subintent):
			guard let preview = state.preview else {
				return .none
			}

			guard preview.requiresSignatures else {
				return handleSignedSubinent(state: &state, signedSubintent: .init(subintent: subintent, subintentSignatures: .init(signatures: [])))
			}

			return .run { send in
				let signedSubintent = try await SargonOS.shared.signSubintent(transactionIntent: subintent, roleKind: .primary)
				await send(.delegate(.signedPreAuthorization(signedSubintent)))

			} catch: { error, send in
				await send(.internal(.resetToApprovable))
				if let error = error as? CommonError, error == .HostInteractionAborted {
					// We don't show any error since user aborted signing intentionally
				} else {
					errorQueue.schedule(error)
				}
			}

		case let .updateSecondsToExpiration(expiration):
			let secondsToExpiration = Int(expiration.timeIntervalSinceNow)
			state.secondsToExpiration = secondsToExpiration
			return secondsToExpiration > 0 ? .none : .cancel(id: CancellableId.expirationTimer)

		case .resetToApprovable:
			return resetToApprovable(&state)
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .sections(.delegate(.failedToResolveSections)):
			state.destination = .rawManifestAlert(.rawManifest)
			return showRawManifest(&state)

		default:
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

	func showRawManifest(_ state: inout State) -> Effect<Action> {
		guard let preview = state.preview else {
			struct MissingPreAuthorizationPreview: Error {}
			errorQueue.schedule(MissingPreAuthorizationPreview())
			return .none
		}

		state.displayMode = .raw(manifest: preview.manifest.manifestString)
		return .none
	}

	func buildSubintent(state: State) -> Effect<Action> {
		guard let preview = state.preview else {
			assertionFailure("Expected preview")
			return .none
		}

		return .run { [expiration = state.expiration, message = state.message] send in
			let subintent = try await preAuthorizationClient.buildSubintent(.init(
				intentDiscriminator: .secureRandom(),
				manifest: preview.manifest,
				expiration: expiration,
				message: message
			))
			await send(.internal(.builtSubintent(subintent)))
		} catch: { error, send in
			loggerGlobal.critical("Failed to build Subintent, error: \(error)")
			errorQueue.schedule(error)
			await send(.internal(.resetToApprovable))
		}
	}

	func resetToApprovable(_ state: inout State) -> Effect<Action> {
		state.isApprovalInProgress = false
		state.sliderResetDate = .now
		state.destination = nil
		return .none
	}

	func handleSignedSubinent(state: inout State, signedSubintent: SignedSubintent) -> Effect<Action> {
		state.destination = nil
		return .send(.delegate(.signedPreAuthorization(signedSubintent)))
	}
}

// MARK: PreAuthorizationReview.CancellableId
extension PreAuthorizationReview {
	private enum CancellableId: Hashable {
		case expirationTimer
	}
}

extension PreAuthorizationReview.State {
	var isExpired: Bool {
		switch expiration {
		case let .atTime(value):
			value.date <= Date.now || secondsToExpiration == 0
		case .afterDelay:
			false
		}
	}
}

private extension AlertState<Never> {
	static var rawManifest: AlertState {
		AlertState {
			TextState(L10n.PreAuthorizationReview.RawManifestAlert.title)
		} actions: {
			.default(TextState(L10n.Common.continue))
		} message: {
			TextState(L10n.PreAuthorizationReview.RawManifestAlert.message)
		}
	}
}
