import SwiftUI

// MARK: - PrimaryTitleTextStyle
public struct PrimaryTitleTextStyle: TextStyleModifier {
	public init() {}

	public func body(content: Content) -> some View {
		content
			.font(.system(size: 26, weight: .semibold))
	}
}

public extension ViewModifier where Self == PrimaryTitleTextStyle {
	static var primaryTitle: Self { Self() }
}

// MARK: - SecondaryTextStyle
public struct SecondaryTextStyle: TextStyleModifier {
	public init() {}

	public func body(content: Content) -> some View {
		content
			.font(.system(size: 16, weight: .regular))
			.foregroundColor(.appGrey2)
	}
}

public extension ViewModifier where Self == SecondaryTextStyle {
	static var secondary: Self { Self() }
}
