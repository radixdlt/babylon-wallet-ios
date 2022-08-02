import ComposableArchitecture
import Foundation

public extension Home {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .component(.header(.coordinate(.displaySettings))):
			return Effect(value: .coordinate(.displaySettings))
		case .component:
			return .none
		case .coordinate:
			return .none
		}
	}
}
