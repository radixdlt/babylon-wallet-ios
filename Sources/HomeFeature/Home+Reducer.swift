import ComposableArchitecture
import Foundation

public extension Home {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		Home.Header.reducer
			.pullback(
				state: \.header,
				action: /Home.Action.header,
				environment: { _ in Home.Header.Environment() }
			),

		Reducer { _, action, _ in
			switch action {
			case .component(.header(.coordinate(.displaySettings))):
				print("BANAN 🔮")
				return Effect(value: .coordinate(.displaySettings))
			case .component:
				return .none
			case .coordinate:
				return .none
			}
		}
	)
}
