import SwiftUI

public struct SecondaryLabel: ViewModifier {
	public init() {}

	public func body(content: Content) -> some View {
		content
			.font(.system(size: 16, weight: .regular))
			.foregroundColor(.appGrey2)
	}
}
