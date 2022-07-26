import SwiftUI

public struct PrimaryTitleLabel: ViewModifier {
	public init() {}

	public func body(content: Content) -> some View {
		content
			.font(.system(size: 26, weight: .semibold))
	}
}
