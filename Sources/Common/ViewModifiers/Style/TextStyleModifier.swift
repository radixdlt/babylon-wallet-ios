import SwiftUI

// MARK: - TextStyleModifier
public protocol TextStyleModifier: ViewModifier {}

public extension View {
	// FIXME: Swift 5.7 - remove generics
	func textStyle<T: TextStyleModifier>(_ textStyle: T) -> some View {
		modifier(textStyle)
	}
}
