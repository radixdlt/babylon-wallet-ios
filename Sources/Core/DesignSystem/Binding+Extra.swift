import SwiftUI

public func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
	.init(
		get: { lhs.wrappedValue ?? rhs },
		set: { lhs.wrappedValue = $0 }
	)
}
