import ComposableArchitecture
import Foundation
import ProfileLoader
import WalletLoader

public extension Splash {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, environment in
		switch action {
		
        case .internal(.system(.viewDidAppear)):
            return .run { send in
                await send(.internal(.system(.loadProfile)))
            }
		
        case .internal(.system(.loadProfile)):
			return .run { send in
				await send(.internal(.system(.loadProfileResult(
					TaskResult {
                        try await environment.profileLoader.loadProfile()
					}
				))))
			}

            
            
            
            
        case let .internal(.system(.loadProfileResult(.success(.some(profile))))):
            return .run { send in
                await send(.internal(.coordinate(.loadProfileResult(SplashLoadProfileResult.profileLoaded(profile)))))
            }
            
        case .internal(.system(.loadProfileResult(.success(.none)))):
            fatalError()
    

		case let .internal(.coordinate(actionToCoordinate)):
			return .run { send in
				let duration: TimeInterval
				#if DEBUG
				duration = 0.1
				#else
				duration = 0.7
				#endif
				try await environment.mainQueue.sleep(for: .seconds(duration))
				await send(.coordinate(actionToCoordinate))
			}

		case .coordinate:
			return .none
		}
	}
}
