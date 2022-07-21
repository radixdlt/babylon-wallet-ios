import ComposableArchitecture
import Foundation

public extension Home {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		/*
		 switch action {
		 case .internal(.user(.removeWallet)):
		     return Effect(value: .internal(.system(.removedWallet)))

		 case .internal(.system(.removedWallet)):
		     return .concatenate(
		         environment
		             .userDefaultsClient
		             .removeProfileName()
		             .subscribe(on: environment.backgroundQueue)
		             .receive(on: environment.mainQueue)
		             .fireAndForget(),

		         Effect(value: .coordinate(.removedWallet))
		     )

		 case .coordinate:
		     return .none
		 }
		 */

		switch action {
		case let .internal(user):
			break
		case let .coordinate(coordinating):
			break
		}
		return .none
	}
}

/*
 case .internal(let user as UserAction) {
 switch user {

 }
 }
 case .internal(let system as SystemAction) {
 switch system {

 }
 }
 */
