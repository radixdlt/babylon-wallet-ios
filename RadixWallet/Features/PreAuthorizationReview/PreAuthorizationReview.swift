// MARK: - PreAuthorizationReview
@Reducer
struct PreAuthorizationReview: Sendable, FeatureReducer {
	typealias Common = InteractionReview

	@ObservableState
	struct State: Sendable, Hashable {
		var dappName: String? = "CaviarNine"
		var dappThumbnail: URL? = .init(string: "https://assets.caviarnine.com/icons/caviarnine_logo_light_400.png")
		var displayMode: Common.DisplayMode = .detailed
		var sliderResetDate: Date = .now // TODO: reset when it corresponds

		var expiration: Expiration?
		var secondsToExpiration: Int?

		// Sections
		var sections: Common.MiddleSections.State = .init()
		var proofs: Common.Proofs.State? = nil

		init() {}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case appeared
		case toggleDisplayModeButtonTapped
		case copyRawTransactionButtonTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case sections(Common.MiddleSections.Action)
		case proofs(Common.Proofs.Action)
	}

	enum InternalAction: Sendable, Equatable {
		case updateSecondsToExpiration(Date)
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.pasteboardClient) var pasteboardClient

	var body: some ReducerOf<Self> {
		Scope(state: \.sections, action: \.child.sections) {
			Common.MiddleSections()
		}
		Reduce(core)
			.ifLet(\.proofs, action: \.child.proofs) {
				Common.Proofs()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			// TODO: Replace mocked data with real logic
			let time = Date().addingTimeInterval(90)
			state.expiration = .atTime(time)
			state.secondsToExpiration = Int(time.timeIntervalSinceNow)
			return startTimer(expirationDate: time)
				.merge(with: getSections())

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
		case let .updateSecondsToExpiration(expiration):
			state.secondsToExpiration = Int(expiration.timeIntervalSinceNow)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .sections(.internal(.setSections(sections))):
			state.proofs = sections?.proofs
			return .none
		default:
			return .none
		}
	}
}

private extension PreAuthorizationReview {
	func getSections() -> Effect<Action> {
		.send(.child(.sections(.internal(.simulate))))
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

private extension PreAuthorizationReview {
	enum CancellableId: Hashable {
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
