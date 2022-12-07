import SwiftUI

// MARK: - LoadingState
// TODO: potentially evolve into a `ControlState` enum with `enabled`, `loading(context: LoadingContext)` and `disabled` cases.
public struct LoadingState {
	public let context: LoadingContext

	public init(context: LoadingContext) {
		self.context = context
	}
}

// MARK: - LoadingContext
public enum LoadingContext {
	case local
	case global(text: String?)
}

extension LoadingState? {
	var isLoading: Bool {
		self != nil
	}

	var isLocal: Bool {
		guard case .local = self?.context else { return false }
		return true
	}

	var isGlobal: Bool {
		guard case .global = self?.context else { return false }
		return true
	}
}

// MARK: - LoadingStateKey
enum LoadingStateKey: EnvironmentKey, PreferenceKey {
	static let defaultValue: LoadingState? = nil

	static func reduce(value: inout LoadingState?, nextValue: () -> LoadingState?) {
		// floats up non-nil loading state from anywhere in the view tree
		if let next = nextValue() {
			value = next
		}
	}
}

extension EnvironmentValues {
	var loadingState: LoadingState? {
		get { self[LoadingStateKey.self] }
		set { self[LoadingStateKey.self] = newValue }
	}
}

public extension View {
	@ViewBuilder
	/// This modifier may only be called once within a view's body.
	/// For multiple loading scenarios, use the `loadingState` modifier instead.
	func isLoading(_ isLoading: Bool, context: LoadingContext) -> some View {
		let state = isLoading ? LoadingState(context: context) : nil
		self.environment(\.loadingState, state)
			.preference(key: LoadingStateKey.self, value: state)
	}

	@ViewBuilder
	func loadingState(_ state: @autoclosure () -> LoadingState?) -> some View {
		let state = state()
		self.environment(\.loadingState, state)
			.preference(key: LoadingStateKey.self, value: state)
	}

	@ViewBuilder
	func loadingState(_ state: () -> LoadingState?) -> some View {
		self.loadingState(state())
	}
}
