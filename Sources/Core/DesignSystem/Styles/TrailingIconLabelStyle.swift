import SwiftUI

extension LabelStyle where Self == TrailingIconLabelStyle {
	/// Applies the `trailingIcon` style with the default spacing
	public static var trailingIcon: Self { .trailingIcon() }

	/// A label style where the icon follows the "title", or text part
	public static func trailingIcon(spacing: CGFloat = .small2) -> Self {
		.init(spacing: spacing)
	}
}

// MARK: - TrailingIconLabelStyle
public struct TrailingIconLabelStyle: LabelStyle {
	let spacing: CGFloat

	public func makeBody(configuration: Configuration) -> some View {
		HStack(spacing: spacing) {
			configuration.title
			configuration.icon
		}
	}
}
