import SwiftUI

extension ButtonStyle where Self == InertButtonStyle {
	public static var inert: Self { .init() }
}

// MARK: - InertButtonStyle
public struct InertButtonStyle: ButtonStyle {
	public func makeBody(configuration: Configuration) -> some View {
		configuration.label.contentShape(Rectangle())
	}
}
