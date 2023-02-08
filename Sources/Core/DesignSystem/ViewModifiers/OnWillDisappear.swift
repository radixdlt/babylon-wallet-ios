import SwiftUI

public extension View {
	func onWillDisappear(perform action: @escaping () -> Void) -> some View {
		self.modifier(OnWillDisappearModifier(onWillDisappear: action))
	}
}

// MARK: - OnWillDisappearModifier
private struct OnWillDisappearModifier: ViewModifier {
	let onWillDisappear: () -> Void

	func body(content: Content) -> some View {
		content.background(Snitch(onWillDisappear: onWillDisappear))
	}
}

// MARK: - Snitch
private struct Snitch: UIViewControllerRepresentable {
	final class ViewController: UIViewController {
		var onWillDisappear: (() -> Void)?

		override func viewWillDisappear(_ animated: Bool) {
			super.viewWillDisappear(animated)
			onWillDisappear?()
		}
	}

	var onWillDisappear: (() -> Void)?

	func makeUIViewController(context: Context) -> some UIViewController {
		let viewController = ViewController()
		viewController.onWillDisappear = onWillDisappear
		return viewController
	}

	func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
