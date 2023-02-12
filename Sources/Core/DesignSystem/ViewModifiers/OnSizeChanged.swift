import SwiftUI

extension View {
	public func onSizeChanged(
		perform action: @escaping (CGSize) -> Void
	) -> some View {
		background(GeometryReader { geo in
			Color.clear
				.preference(key: CGSizePreferenceKey.self, value: geo.size)
		})
		.onPreferenceChange(CGSizePreferenceKey.self) { value in
			action(value)
		}
	}
}

// MARK: - CGSizePreferenceKey
private enum CGSizePreferenceKey: PreferenceKey {
	static var defaultValue: CGSize = .zero

	static func reduce(value _: inout CGSize, nextValue: () -> CGSize) {
		_ = nextValue()
	}
}
