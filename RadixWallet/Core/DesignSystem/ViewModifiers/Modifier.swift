
extension View {
	func modifier<ModifiedContent>(
		@ViewBuilder _ modifier: (Self) -> ModifiedContent
	) -> ModifiedContent {
		modifier(self)
	}
}
