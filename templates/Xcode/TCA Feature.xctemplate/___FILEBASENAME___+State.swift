import Foundation

// MARK: - ___VARIABLE_featureName___.State
public extension ___VARIABLE_featureName___ {
	struct State: Sendable, Equatable {
		public init() {}
	}
}

#if DEBUG
public extension ___VARIABLE_featureName___.State {
	static let previewValue: Self = .init()
}
#endif
