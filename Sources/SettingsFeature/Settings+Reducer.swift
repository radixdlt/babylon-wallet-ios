import ComposableArchitecture

public extension Settings {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, _, _ in
		.none
	}
}
