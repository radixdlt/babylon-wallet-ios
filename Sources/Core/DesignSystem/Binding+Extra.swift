import SwiftUI

extension Binding where Value: Equatable {
	public func removeDuplicates() -> Self {
		.init(
			get: { self.wrappedValue },
			set: { newValue, transaction in
				guard newValue != self.wrappedValue else { return }
				self.transaction(transaction).wrappedValue = newValue
			}
		)
	}
}

extension Binding {
	public static func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
		.init(
			get: { lhs.wrappedValue ?? rhs },
			set: { lhs.wrappedValue = $0 }
		)
	}
}
