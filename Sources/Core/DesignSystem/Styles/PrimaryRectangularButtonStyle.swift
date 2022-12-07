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

// MARK: - IsLoadingKey
private enum IsLoadingKey: EnvironmentKey, PreferenceKey {
	// TODO: evolve into enum with `enabled`, `loading(global: Bool)` and `disabled` cases.
	static let defaultValue = (isLoading: false, configuration: LoadingConfiguration?.none)

	static func reduce(value: inout Value, nextValue: () -> Value) {
		// prioritizes isLoading = true, as it indicates loading is happening somewhere in the view tree
		// regardless of the parent preference
		if !value.isLoading {
			value = nextValue()
		}
	}
}

extension EnvironmentValues {
	var isLoading: Bool {
		get { self[IsLoadingKey.self].isLoading }
		set { self[IsLoadingKey.self] = (newValue, nil) }
	}
}

// MARK: - LoadingConfiguration
public enum LoadingConfiguration {
	case global(text: String?)
}

public extension View {
	func isLoading(_ isLoading: Bool, _ configuration: LoadingConfiguration? = nil) -> some View {
		environment(\.isLoading, isLoading)
			.preference(key: IsLoadingKey.self, value: (isLoading, configuration))
	}
}
