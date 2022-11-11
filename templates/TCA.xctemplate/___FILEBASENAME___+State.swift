import Foundation

// MARK: - ___VARIABLE_moduleName___.State
public extension ___VARIABLE_moduleName___ {
	struct State: Equatable {
		public init() {}
	}
}

#if DEBUG
public extension ___VARIABLE_moduleName___.State {
	static let placeholder: Self = .init()
}
#endif
