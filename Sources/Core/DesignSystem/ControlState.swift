import SwiftUI

// MARK: - ControlState
// TODO: potentially evolve into a `ControlState` enum with `enabled`, `loading(context: LoadingContext)` and `disabled` cases.
public enum ControlState: Equatable {
	case enabled
	case loading(LoadingContext)
	case disabled

	public var isEnabled: Bool {
		guard case .enabled = self else { return false }
		return true
	}

	public var isLoading: Bool {
		guard case .loading = self else { return false }
		return true
	}

	public var isDisabled: Bool {
		guard case .disabled = self else { return false }
		return true
	}
}

// MARK: - LoadingContext
public enum LoadingContext: Equatable {
	case local
	case global(text: String?)
}

// MARK: - ControlStateKey
enum ControlStateKey: EnvironmentKey {
	static let defaultValue: ControlState = .enabled
}

// MARK: - LoadingContextKey
enum LoadingContextKey: PreferenceKey {
	static let defaultValue: LoadingContext? = nil

	static func reduce(value: inout LoadingContext?, nextValue: () -> LoadingContext?) {
		// floats up non-nil loading state from anywhere in the view tree
		if let next = nextValue() {
			value = next
		}
	}
}

extension EnvironmentValues {
	var controlState: ControlState {
		get { self[ControlStateKey.self] }
		set { self[ControlStateKey.self] = newValue }
	}
}

public extension View {
	/// This modifier may only be called once within a view's body.
	/// When applied multiple times, only the last modifier will be applied.
	/// For multiple loading scenarios, use the `controlState` modifier instead.
	@available(*, deprecated, message: "Compute the appropriate 'ControlState' from your TCA State and use the 'controlState' modifier instead.")
	func isLoading(_ isLoading: Bool, context: LoadingContext) -> some View {
		self.transformEnvironment(\.controlState) {
			if isLoading {
				$0 = .loading(context)
			}
		}
		.transformPreference(LoadingContextKey.self) {
			if isLoading {
				$0 = context
			}
		}
		.disabled(isLoading)
	}

	@available(*, deprecated, message: "Compute the appropriate 'ControlState' from your TCA State and use the non-closure based 'controlState' modifier instead.")
	func controlState(_ state: () -> ControlState) -> some View {
		self.controlState(state())
	}

	func controlState(_ state: ControlState) -> some View {
		self.environment(\.controlState, state)
			.transformPreference(LoadingContextKey.self) {
				switch state {
				case let .loading(context):
					$0 = context
				case .enabled, .disabled:
					break
				}
			}
			.disabled(state != .enabled)
	}
}
