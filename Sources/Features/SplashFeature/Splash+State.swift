import ComposableArchitecture
import Foundation

// MARK: Splash.State
public extension Splash {
	// MARK: State
	struct State: Equatable {
		public var alert: AlertState<Action.ViewAction>?

		public init(
			alert: AlertState<Action.ViewAction>? = nil
		) {
			self.alert = alert
		}
	}
}
