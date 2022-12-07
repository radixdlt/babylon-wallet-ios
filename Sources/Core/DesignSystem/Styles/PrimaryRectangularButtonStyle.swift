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

// MARK: - LoadingConfiguration
public enum LoadingConfiguration {
	case global(text: String?)
}

// MARK: - LoadingStateKey
enum LoadingStateKey: EnvironmentKey, PreferenceKey {
	// TODO: evolve into a `ControlState` enum with `enabled`, `loading(configuration: LoadingConfiguration)` and `disabled` cases.
	struct LoadingState {
		let isLoading: Bool
		let configuration: LoadingConfiguration?
	}

	static let defaultValue: LoadingState = .init(isLoading: false, configuration: nil)

	static func reduce(value: inout LoadingState, nextValue: () -> LoadingState) {
		// float up isLoading = true if happening somewhere in the view tree regardless of the parent preference
		if !value.isLoading {
			value = nextValue()
		}
	}
}

extension EnvironmentValues {
	var isLoading: Bool {
		get { self[LoadingStateKey.self].isLoading }
		set { self[LoadingStateKey.self] = .init(isLoading: newValue, configuration: nil) }
	}
}

public extension View {
	func isLoading(_ isLoading: Bool, _ configuration: LoadingConfiguration? = nil) -> some View {
		self.environment(\.isLoading, isLoading)
			.preference(key: LoadingStateKey.self, value: .init(isLoading: isLoading, configuration: configuration))
	}
}
