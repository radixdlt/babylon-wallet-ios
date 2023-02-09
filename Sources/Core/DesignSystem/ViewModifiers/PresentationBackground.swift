#if os(iOS)
import Introspect
import Prelude
import SwiftUI

public enum PresentationBackground {
	case blur(style: UIBlurEffect.Style)

	public static let blur: Self = .blur(style: .systemUltraThinMaterialDark)
}

public extension View {
	func presentationBackground(_ background: PresentationBackground) -> some View {
		self.modifier(PresentationBackgroundModifier(background: background))
	}
}

// MARK: - PresentationDetentBlurBackgroundModifier
private struct PresentationBackgroundModifier: ViewModifier {
	let background: PresentationBackground

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

				let backgroundView: UIView = {
					switch background {
					case let .blur(style):
						return with(UIVisualEffectView(effect: UIBlurEffect(style: style))) {
							$0.frame = containerView.bounds
							$0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
						}
					}
				}()
				containerView.insertSubview(backgroundView, at: 0)

				// TODO: find a way to make this work
//				sheetPresentationController.swizzle(
//					original: #selector(UIPresentationController.presentationTransitionWillBegin),
//					swizzled: #selector(UIPresentationController.swizzled_presentationTransitionWillBegin)
//				)
//				sheetPresentationController.additionalPresentationAnimation = {
//					viewController.transitionCoordinator?.animate(alongsideTransition: { context in
//						backgroundView.alpha = 1
//					})
//				}
				// Workaround for now
				backgroundView.alpha = 0
				UIView.animate(
					withDuration: 0.35,
					delay: 0,
					options: [.curveEaseInOut],
					animations: { backgroundView.alpha = 1 }
				)

				sheetPresentationController.swizzle(
					original: #selector(UIPresentationController.dismissalTransitionWillBegin),
					swizzled: #selector(UIPresentationController.swizzled_dismissalTransitionWillBegin)
				)
				sheetPresentationController.additionalDismissalAnimation = {
					viewController.transitionCoordinator?.animate(alongsideTransition: { _ in
						backgroundView.alpha = 0
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
