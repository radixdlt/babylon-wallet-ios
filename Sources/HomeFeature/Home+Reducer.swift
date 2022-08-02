import ComposableArchitecture
import Foundation

public extension Home {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, _, _ in
//		switch action {
		//        case .component(.header(.coordinate(.displaySettings))):
		//            return Effect(value: .coordinate(.displaySettings))
		//        case .component:
//			break
		//        case .coordinate:
		//            break
//		}
		.none
	}
}
