#if os(iOS)
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

	func body(content: Content) -> some View {
		content
			.introspectViewController { viewController in
				guard
					let sheetPresentationController = viewController.sheetPresentationController,
					let containerView = sheetPresentationController.containerView
				else {
					return
				}

				sheetPresentationController.largestUndimmedDetentIdentifier = .large

				let blurEffectView = with(UIVisualEffectView(effect: UIBlurEffect(style: style))) {
					$0.frame = containerView.bounds
					$0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
				}
				containerView.insertSubview(blurEffectView, at: 0)

				// TODO: find a way to make this work
//				sheetPresentationController.swizzle(
//					original: #selector(UIPresentationController.presentationTransitionWillBegin),
//					swizzled: #selector(UIPresentationController.swizzled_presentationTransitionWillBegin)
//				)
//				sheetPresentationController.additionalPresentationAnimation = {
//					viewController.transitionCoordinator?.animate(alongsideTransition: { context in
//						blurEffectView.alpha = 1
//					})
//				}
				// Workaround for now
				blurEffectView.alpha = 0
				UIView.animate(
					withDuration: 0.35,
					delay: 0,
					options: [.curveEaseInOut],
					animations: { blurEffectView.alpha = 1 }
				)

				sheetPresentationController.swizzle(
					original: #selector(UIPresentationController.dismissalTransitionWillBegin),
					swizzled: #selector(UIPresentationController.swizzled_dismissalTransitionWillBegin)
				)
				sheetPresentationController.additionalDismissalAnimation = {
					viewController.transitionCoordinator?.animate(alongsideTransition: { _ in
						blurEffectView.alpha = 0
					})
				}
			}
	}
}

private extension UIPresentationController {
	@objc dynamic func swizzled_dismissalTransitionWillBegin() {
		swizzled_dismissalTransitionWillBegin()
		additionalDismissalAnimation?()
	}

	@objc dynamic func swizzled_presentationTransitionWillBegin() {
		swizzled_presentationTransitionWillBegin()
		additionalPresentationAnimation?()
	}
}

private extension UIPresentationController {
	var additionalPresentationAnimation: (() -> Void)? {
		get {
			let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
			return objc_getAssociatedObject(self, key) as? () -> Void
		}
		set {
			let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
			objc_setAssociatedObject(self, key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}

	var additionalDismissalAnimation: (() -> Void)? {
		get {
			let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
			return objc_getAssociatedObject(self, key) as? () -> Void
		}
		set {
			let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
			objc_setAssociatedObject(self, key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
}

private extension UIPresentationController {
	static var swizzledSelectors: [Selector: Void] = [:]

	func swizzle(
		original originalSelector: Selector,
		swizzled swizzledSelector: Selector
	) {
		guard Self.swizzledSelectors[originalSelector] == nil else {
			return
		}

		guard let myClass = object_getClass(self) else {
			return
		}

		guard let swizzledMethod = class_getInstanceMethod(UIPresentationController.self, swizzledSelector) else {
			return
		}

		if let originalMethod = class_getInstanceMethod(myClass, originalSelector) {
			// exchange implementation
			method_exchangeImplementations(originalMethod, swizzledMethod)
		} else {
			// add implementation
			class_addMethod(myClass, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
		}

		Self.swizzledSelectors[originalSelector] = ()
	}
}
#endif
