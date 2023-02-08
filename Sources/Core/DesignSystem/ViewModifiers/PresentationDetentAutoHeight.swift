import SwiftUI

public extension View {
	func presentationDetentAutoHeight() -> some View {
		self.modifier(FixedInnerHeightViewModifier())
	}
}

// MARK: - FixedInnerHeightViewModifier
private struct FixedInnerHeightViewModifier: ViewModifier {
	@State private var sheetHeight: CGFloat = .zero

	func body(content: Content) -> some View {
		content
			.overlay {
				GeometryReader { proxy in
					Color.clear.preference(key: InnerHeightPreferenceKey.self, value: proxy.size.height)
				}
			}
			.onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in sheetHeight = newHeight }
			.presentationDetents([.height(sheetHeight)])
	}
}

// MARK: - InnerHeightPreferenceKey
private struct InnerHeightPreferenceKey: PreferenceKey {
	static var defaultValue: CGFloat = .zero

	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = nextValue()
	}
}
