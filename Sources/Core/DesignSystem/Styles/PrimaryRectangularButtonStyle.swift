import SwiftUI

// MARK: - PrimaryRectangularButtonStyle
public struct PrimaryRectangularButtonStyle: ButtonStyle {
	@Environment(\.isEnabled) var isEnabled: Bool
	@Environment(\.isLoading) var isLoading: Bool

	public func makeBody(configuration: Configuration) -> some View {
		ZStack {
			configuration.label
				.foregroundColor(foregroundColor)
				.font(.app.body1Header)
				.frame(maxWidth: .infinity)
				.frame(height: .standardButtonHeight)
				.background(isEnabled ? Color.app.blue2 : Color.app.gray4)
				.cornerRadius(.small2)
				.brightness(configuration.isPressed ? -0.1 : 0)

			if isLoading {
				LoadingView()
					.frame(width: .medium3, height: .medium3)
			}
		}
		.allowsHitTesting(!isLoading)
	}
}

private extension PrimaryRectangularButtonStyle {
	var foregroundColor: Color {
		if isLoading {
			return .clear
		} else if isEnabled {
			return .app.white
		} else {
			return .app.gray3
		}
	}
}

public extension ButtonStyle where Self == PrimaryRectangularButtonStyle {
	static var primaryRectangular: Self { Self() }
}

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
	var isLoading: Bool { self[LoadingStateKey.self] != nil }

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
