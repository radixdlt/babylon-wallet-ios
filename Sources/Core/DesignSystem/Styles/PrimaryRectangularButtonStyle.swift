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
				LoaderView()
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
private struct IsLoadingKey: EnvironmentKey {
	static let defaultValue: Bool = false
}

extension EnvironmentValues {
	var isLoading: Bool {
		get { self[IsLoadingKey.self] }
		set { self[IsLoadingKey.self] = newValue }
	}
}

public extension View {
	func isLoading(_ value: Bool) -> some View {
		environment(\.isLoading, value)
	}
}
