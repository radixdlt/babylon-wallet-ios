import SwiftUI

public extension View {
	func synchronize<Value>(
		_ first: Binding<Value>,
		_ second: FocusState<Value>.Binding
	) -> some View {
		onChange(of: first.wrappedValue) { second.wrappedValue = $0 }
			.onChange(of: second.wrappedValue) { first.wrappedValue = $0 }
	}

	@available(*, deprecated, message: "Use 'controlState(.enabled/.disabled)' instead.")
	@inlinable
	func enabled(_ enabled: @autoclosure () -> Bool) -> some View {
		disabled(!enabled())
	}
}
