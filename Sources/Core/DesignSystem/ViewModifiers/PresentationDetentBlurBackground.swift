import Introspect
import Prelude
import SwiftUI

public extension View {
	func presentationDetentBlurBackground(
		style: UIBlurEffect.Style = .systemUltraThinMaterialDark
	) -> some View {
		self.modifier(PresentationDetentBlurBackgroundModifier(style: style))
	}
}

// MARK: - PresentationDetentBlurBackgroundModifier
private struct PresentationDetentBlurBackgroundModifier: ViewModifier {
	let style: UIBlurEffect.Style
	let animationDuration = 0.35

	@State var blurEffectView: UIView?

	func body(content: Content) -> some View {
		content
			.introspectViewController { viewController in
				guard
					let containerView = viewController.sheetPresentationController?.containerView
				else {
					return
				}
				self.blurEffectView = with(UIVisualEffectView(effect: UIBlurEffect(style: style))) {
					$0.frame = containerView.bounds
					$0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
					$0.alpha = 0

					containerView.backgroundColor = .clear
					containerView.insertSubview($0, at: 0)

					UIView.animate(
						withDuration: animationDuration,
						delay: 0,
						options: [.curveEaseInOut],
						animations: { [blurEffectView = $0] in
							blurEffectView.alpha = 1
						}
					)
				}
			}
			.background(Snitch(willDisappear: {
				UIView.animate(
					withDuration: animationDuration,
					delay: 0,
					options: [.curveEaseInOut],
					animations: {
						blurEffectView?.alpha = 0
					}
				)
			}))
	}
}

// MARK: - Snitch
private struct Snitch: UIViewControllerRepresentable {
	final class ViewController: UIViewController {
		var willDisappear: (() -> Void)?

		override func viewWillDisappear(_ animated: Bool) {
			super.viewWillDisappear(animated)
			willDisappear?()
		}
	}

	var willDisappear: (() -> Void)?

	func makeUIViewController(context: Context) -> some UIViewController {
		with(ViewController()) {
			$0.willDisappear = willDisappear
		}
	}

	func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
