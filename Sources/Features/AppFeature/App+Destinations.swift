import FeaturePrelude

extension App {
	public struct Alerts: Sendable, ReducerProtocol {
		public enum State: Sendable, Equatable {
			case userErrorAlert(AlertState<Action.UserErrorAlertAction>)
			case incompatibleProfileErrorAlert(AlertState<Action.IncompatibleProfileErrorAlertAction>)
		}

		public enum Action: Sendable, Equatable {
			case userErrorAlert(UserErrorAlertAction)
			case incompatibleProfileErrorAlert(IncompatibleProfileErrorAlertAction)

			public enum UserErrorAlertAction: Sendable, Equatable {
				// NB: no actions, just letting the system show the default "OK" button
			}

			public enum IncompatibleProfileErrorAlertAction: Sendable, Equatable {
				case deleteWalletDataButtonTapped
			}
		}

		public var body: some ReducerProtocolOf<Self> {
			EmptyReducer()
		}
	}
}
