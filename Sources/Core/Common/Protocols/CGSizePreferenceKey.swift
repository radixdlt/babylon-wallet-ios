import SwiftUI

// MARK: - CGSizePreferenceKey
public protocol CGSizePreferenceKey: PreferenceKey where Value == CGSize {}

public extension CGSizePreferenceKey {
	static func reduce(value _: inout CGSize, nextValue: () -> CGSize) {
		_ = nextValue()
	}
}

public extension View {
	func onSizeChanged<Key: CGSizePreferenceKey>(
		_ key: Key.Type,
		perform action: @escaping (CGSize) -> Void
	) -> some View {
		background(GeometryReader { geo in
			Color.clear
				.preference(key: Key.self, value: geo.size)
		})
		.onPreferenceChange(key) { value in
			action(value)
		}
	}
}

// MARK: - ReferenceView
public struct ReferenceView: CGSizePreferenceKey {
	public static var defaultValue: CGSize = .zero
}
