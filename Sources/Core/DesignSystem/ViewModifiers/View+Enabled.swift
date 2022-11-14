import Foundation
import SwiftUI

public extension View {
	@inlinable
	func enabled(_ enabled: @autoclosure () -> Bool) -> some View {
		disabled(!enabled())
	}
}
