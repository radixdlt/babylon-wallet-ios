// MARK: - OnFirstTaskViewModifier
struct OnFirstTaskViewModifier: ViewModifier {
	let priority: TaskPriority
	let action: @Sendable () async -> Void

	@State private var didFire = false

	func body(content: Content) -> some View {
		content.task(priority: priority) {
			guard !didFire else {
				return
			}
			didFire = true
			await action()
		}
	}
}

extension View {
	/// Executes a given action only once, when the first `task` is fired by the system.
	public func onFirstTask(
		priority: TaskPriority = .userInitiated,
		_ action: @escaping @Sendable () async -> Void
	) -> some View {
		modifier(OnFirstTaskViewModifier(priority: priority, action: action))
	}
}
