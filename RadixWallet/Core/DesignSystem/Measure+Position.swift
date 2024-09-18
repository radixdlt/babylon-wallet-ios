import Foundation

extension View {
	public func measurePosition(_ id: AnyHashable?, coordSpace: String) -> some View {
		background {
			if let id {
				GeometryReader { proxy in
					Color.clear
						.preference(key: PositionsPreferenceKey.self, value: [id: proxy.frame(in: .named(coordSpace))])
				}
			} else {
				Color.clear
			}
		}
	}
}

// MARK: - PositionsPreferenceKey
public enum PositionsPreferenceKey: PreferenceKey {
	public static var defaultValue: [AnyHashable: CGRect] = [:]

	public static func reduce(value: inout [AnyHashable: CGRect], nextValue: () -> [AnyHashable: CGRect]) {
		value.merge(nextValue()) { $1 }
	}
}

extension View {
	public func measureSize(_ id: AnyHashable) -> some View {
		background {
			GeometryReader { proxy in
				Color.clear
					.preference(key: PositionsPreferenceKey.self, value: [id: proxy.frame(in: .local)])
			}
		}
	}

	public func onReadPosition(_ id: AnyHashable, action: @escaping (CGRect) -> Void) -> some View {
		onPreferenceChange(PositionsPreferenceKey.self) { positions in
			if let position = positions[id] {
				action(position)
			}
		}
	}

	public func onReadSizes(_ id1: AnyHashable, _ id2: AnyHashable, action: @escaping (CGSize, CGSize) -> Void) -> some View {
		onPreferenceChange(PositionsPreferenceKey.self) { positions in
			if let size1 = positions[id1]?.size, let size2 = positions[id2]?.size {
				action(size1, size2)
			}
		}
	}
}
