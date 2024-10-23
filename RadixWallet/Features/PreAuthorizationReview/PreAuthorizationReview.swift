// MARK: - PreAuthorizationReview
struct PreAuthorizationReview: Sendable, FeatureReducer {
	typealias Common = InteractionReview

	struct State: Sendable, Hashable {
		let unvalidatedManifest: UnvalidatedTransactionManifest
		let nonce: Nonce
		let signTransactionPurpose: SigningPurpose.SignTransactionPurpose
		let ephemeralNotaryPrivateKey: Curve25519.Signing.PrivateKey = .init()

		var reviewedPreAuthorization: ReviewedPreAuthorization?
		var dAppName: String? = "CaviarNine"
		var dAppThumbnail: URL? = .init(string: "https://assets.caviarnine.com/icons/caviarnine_logo_light_400.png")
		var displayMode: Common.DisplayMode = .detailed
		var sliderResetDate: Date = .now // TODO: reset when it corresponds

		var expiration: Expiration?
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
		case previewLoaded(TaskResult<TransactionToReview>)
		case updateSecondsToExpiration(Date)
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.transactionClient) var transactionClient

	var body: some ReducerOf<Self> {
		Scope(state: \.sections, action: \.child.sections) {
			Common.Sections()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			// TODO: Replace mocked data with real logic
			return .run { [state = state] send in
				let preview = await TaskResult {
					try await transactionClient.getTransactionReview(.init(
						unvalidatedManifest: state.unvalidatedManifest,
						message: .none,
						nonce: state.nonce,
						ephemeralNotaryPublicKey: state.ephemeralNotaryPrivateKey.publicKey,
						signingPurpose: .signTransaction(state.signTransactionPurpose), // Update
						isWalletTransaction: true
					))
				}
				await send(.internal(.previewLoaded(preview)))
			}

		case .toggleDisplayModeButtonTapped:
			switch state.displayMode {
			case .detailed:
				state.displayMode = .raw(state.exampleRaw)
			case .raw:
				state.displayMode = .detailed
			}
			return .none

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
			// TODO: Handle error
			return .none

		case let .previewLoaded(.success(preview)):
			state.reviewedPreAuthorization = .init(manifest: preview.transactionManifest)
			let time = Date().addingTimeInterval(90)
			state.expiration = .atTime(time)
			state.secondsToExpiration = Int(time.timeIntervalSinceNow)
			return startTimer(expirationDate: time)
				.merge(with: getSections(executionSummary: preview.analyzedManifestToReview, networkId: preview.networkID))

		case let .updateSecondsToExpiration(expiration):
			state.secondsToExpiration = Int(expiration.timeIntervalSinceNow)
			return .none
		}
	}
}

private extension PreAuthorizationReview {
	func getSections(executionSummary: ExecutionSummary, networkId: NetworkID) -> Effect<Action> {
		.send(.child(.sections(.internal(.parent(.resolveExecutionSummary(executionSummary, networkId))))))
	}

	func startTimer(expirationDate: Date) -> Effect<Action> {
		.run { send in
			for await _ in self.clock.timer(interval: .seconds(1)) {
				await send(.internal(.updateSecondsToExpiration(expirationDate)))
			}
		}
		.cancellable(id: CancellableId.expirationTimer, cancelInFlight: true)
	}
}

extension PreAuthorizationReview {
	private enum CancellableId: Hashable {
		case expirationTimer
	}

	struct ReviewedPreAuthorization: Sendable, Hashable {
		let manifest: TransactionManifest

		// TODO: Fill required info once we have Sargon ready
	}
}

extension PreAuthorizationReview.State {
	var isExpired: Bool {
		switch expiration {
		case let .atTime(date):
			date <= Date.now
		case .window, .none:
			false
		}
	}
}

extension PreAuthorizationReview.State {
	var exampleRaw: String {
		"""
		CALL_METHOD
		Address("account_tdx_2_12ytkalad6hfxamsz4a7r8tevz7ahurfj58dlp4phl4nca5hs0hpu90")
		"lock_fee"
		Decimal("0.3696274912355")
		;
		CALL_METHOD
		Address("account_tdx_2_12ytkalad6hfxamsz4a7r8tevz7ahurfj58dlp4phl4nca5hs0hpu90")
		"withdraw"
		Address("resource_tdx_2_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxtfd2jc")
		Decimal("2")
		;
		TAKE_FROM_WORKTOP
		Address("resource_tdx_2_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxtfd2jc")
		Decimal("2")
		Bucket("bucket1")
		;
		CALL_METHOD
		Address("account_tdx_2_12x2hd6m7z9n389u47sn7qhv3cmeqseyathrpqa2mwlx8wczrpd36ar")
		"try_deposit_or_abort"
		Bucket("bucket1")
		Enum<0u8>()
		;

		"""
	}
}

// MARK: - Expiration
enum Expiration: Sendable, Hashable {
	// TODO: Replace with Sargon model
	case atTime(Date)
	case window(Int)
}
