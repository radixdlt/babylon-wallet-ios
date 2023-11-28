// MARK: - OnFirstAppearViewModifier
struct OnFirstAppearViewModifier: ViewModifier {
	let priority: TaskPriority
	let action: () -> Void

	@State private var didFire = false
	@State private var id = UUID()

	func body(content: Content) -> some View {
		content.onAppear {
			guard !didFire else {
				loggerGlobal.debug("OnFirstAppearViewModifier id=\(id) NOT firing, already fired")
				return
			}
			didFire = true
			loggerGlobal.debug("OnFirstAppearViewModifier id=\(id) not fired, firing now!")
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
