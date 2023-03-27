import SwiftUI

extension View {
	public func modifier<ModifiedContent>(
		@ViewBuilder _ modifier: (Self) -> ModifiedContent
	) -> ModifiedContent {
		modifier(self)
	}
}
