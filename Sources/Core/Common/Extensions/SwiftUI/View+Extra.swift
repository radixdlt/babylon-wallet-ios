import SwiftUI

public extension View {
	@available(*, deprecated, message: "Use 'controlState(.enabled/.disabled)' instead.")
	@inlinable
	func enabled(_ enabled: @autoclosure () -> Bool) -> some View {
		disabled(!enabled())
	}
}
