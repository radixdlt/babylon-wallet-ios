import FeaturePrelude

// MARK: - DappInteraction.Action
public extension DappInteraction {
	enum Action: Sendable, Equatable {
		case view(ViewAction)
		case `internal`(InternalAction)
		case child(ChildAction)
		case delegate(DelegateAction)

		public enum ViewAction: Sendable, Equatable {
			case appeared
		}

		public enum InternalAction: Sendable, Equatable {}

		public enum ChildAction: Sendable, Equatable {
			case navigation(NavigationActionOf<DappInteraction.Destinations>)
		}

		public enum DelegateAction: Sendable, Equatable {}
	}
}
