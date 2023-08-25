import SwiftUI

// MARK: - ControlState
public enum ControlState: Sendable, Hashable {
	case enabled
	case loading(LoadingContext)
	case disabled

	public var isEnabled: Bool {
		self == .enabled
	}

	public var isLoading: Bool {
		guard case .loading = self else { return false }
		return true
	}

	public var isDisabled: Bool {
		self == .disabled
	}
}

// MARK: - LoadingContext
public enum LoadingContext: Sendable, Hashable {
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

extension View {
	public func controlState(_ state: ControlState) -> some View {
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
