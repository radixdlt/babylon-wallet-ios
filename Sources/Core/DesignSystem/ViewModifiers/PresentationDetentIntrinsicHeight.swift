import SwiftUI

extension View {
	public func presentationDetentIntrinsicHeight() -> some View {
		self.modifier(PresentationDetentIntrinsicHeight())
	}
}

// MARK: - PresentationDetentIntrinsicHeight
private struct PresentationDetentIntrinsicHeight: ViewModifier {
	@State private var sheetHeight: CGFloat = .zero

	func body(content: Content) -> some View {
		content
			.overlay {
				GeometryReader { proxy in
					Color.clear.preference(key: IntrinsicHeightPreferenceKey.self, value: proxy.size.height)
				}
			}
			.onPreferenceChange(IntrinsicHeightPreferenceKey.self) { newHeight in sheetHeight = newHeight }
			.presentationDetents([.height(sheetHeight)])
	}
}

// MARK: - IntrinsicHeightPreferenceKey
private struct IntrinsicHeightPreferenceKey: PreferenceKey {
	static var defaultValue: CGFloat = .zero

	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = nextValue()
	}
}
