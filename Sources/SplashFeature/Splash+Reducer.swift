import ComposableArchitecture

public extension Splash {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, environment in
		switch action {
		case .internal(.system(.viewDidAppear)):
			return Effect(value: .internal(.system(.loadProfile)))
		case .internal(.system(.loadProfile)):
			return .run { send in
				let profile = try await environment.profileLoader.loadProfile()
				await send(.internal(.system(.loadProfileResult(.success(profile)))))
			}

		case let .internal(.system(.loadProfileResult(.success(profile)))):
			return Effect(value: .internal(.system(.loadWalletWithProfile(profile))))

		case let .internal(.system(.loadProfileResult(.failure(error)))):
			return Effect(value: .internal(.coordinate(.loadWalletResult(.noWallet(reason: "Failed to load profile")))))

		case let .internal(.system(.loadWalletWithProfile(profile))):
			return .run { send in
				let wallet = try await environment.walletLoader.loadWallet(profile)
				await send(.internal(.system(.loadWalletWithProfileResult(.success(wallet), profile: profile))))
			}

		case let .internal(.system(.loadWalletWithProfileResult(.success(wallet), _))):
			return Effect(value: .internal(.coordinate(.loadWalletResult(.walletLoaded(wallet)))))

		case .internal(.system(.loadWalletWithProfileResult(.failure, _))):
			return Effect(value: .internal(.coordinate(.loadWalletResult(.noWallet(reason: "Failed to load profile")))))

		case let .internal(.coordinate(actionToCoordinate)):
			return Effect(value: .coordinate(actionToCoordinate))
				.delay(for: 0.7, scheduler: environment.mainQueue)
				.eraseToEffect()
		case .coordinate:
			return .none
		}
	}
}
