// MARK: - OnFirstAppearViewModifier
struct OnFirstAppearViewModifier: ViewModifier {
	let id = UUID()
	let priority: TaskPriority
	let action: () -> Void

	@State private var didFire = false

	func body(content: Content) -> some View {
		content.onAppear {
			guard !didFire else {
				loggerGlobal.debug("OnFirstAppearViewModifier ID=\(self.id) NOT firing, already fired")
				return
			}
			didFire = true
			loggerGlobal.debug("OnFirstAppearViewModifier ID=\(self.id) not fired, firing now!")
			action()
		}
	}
}

extension View {
	/// Executes a given action only once, when the first `onAppear` is fired by the system.
	public func onFirstAppear(
		priority: TaskPriority = .userInitiated,
		_ action: @escaping () -> Void
	) -> some View {
		modifier(OnFirstAppearViewModifier(priority: priority, action: action))
	}
}
