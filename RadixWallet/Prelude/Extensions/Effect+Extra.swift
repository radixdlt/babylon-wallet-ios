import ComposableArchitecture

extension Effect {
	public static var resignFirstResponder: Effect {
		.run { _ in
			await MainActor.run {
				_ = UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
			}
		}
	}
}
