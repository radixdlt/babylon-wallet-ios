#if os(iOS)
import Introspect
import Prelude
import SwiftUI

public enum PresentationBackground {
	case blur(style: UIBlurEffect.Style)

	public static let blur: Self = .blur(style: .systemUltraThinMaterialDark)
}

extension View {
	public func presentationBackground(_ background: PresentationBackground) -> some View {
		self.modifier(PresentationBackgroundModifier(background: background))
	}
}

// MARK: - PresentationDetentBlurBackgroundModifier
private struct PresentationBackgroundModifier: ViewModifier {
	let background: PresentationBackground

	func body(content: Content) -> some View {
		content
			// hands us the view controller corresponding to the SwiftUI view this modifier is attached
			// to as soon as it's added to its parent view/window
			.introspectViewController { viewController in
				// attempt to get the controller in which this sheet is being presented
				// and grab its container view
				guard
					let sheetPresentationController = viewController.sheetPresentationController,
					let containerView = sheetPresentationController.containerView
				else {
					return
				}

				// disable standard background dimming altogether, as we're going to use our own
				sheetPresentationController.largestUndimmedDetentIdentifier = .large

				// initialize background view and apply the chosen visual effects to it
				let backgroundView: UIView = {
					switch background {
					case let .blur(style):
						return with(UIVisualEffectView(effect: UIBlurEffect(style: style))) {
							$0.frame = containerView.bounds
							$0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
						}
					}
				}()
				// add the background view at the very back of the container hierarchy
				containerView.insertSubview(backgroundView, at: 0)

				// TODO: @davdroman find a way to make this work post betanet v2, otherwise
				// settle for current workaround which is near perfect anyway.
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
				// rudimentarily dims in background view
				backgroundView.alpha = 0
				UIView.animate(
					withDuration: 0.35,
					delay: 0,
					options: [.curveEaseInOut],
					animations: { backgroundView.alpha = 1 }
				)

				// hook into dismissalTransitionWillBegin via swizzling in order to layer in additional
				// dismissal animation behavior
				// ref: https://developer.apple.com/documentation/uikit/uipresentationcontroller/1618342-dismissaltransitionwillbegin
				sheetPresentationController.swizzle(
					original: #selector(UIPresentationController.dismissalTransitionWillBegin),
					swizzled: #selector(UIPresentationController.swizzled_dismissalTransitionWillBegin)
				)
				// define said additional dismissal animation behavior
				sheetPresentationController.additionalDismissalAnimation = {
					// in this case, it fades out the background view as the user drags down
					// to dismiss or the user is dismissed via a button, etc
					viewController.transitionCoordinator?.animate(alongsideTransition: { _ in
						backgroundView.alpha = 0
					})
				}
			}
	}
}

extension UIPresentationController {
	@objc fileprivate dynamic func swizzled_dismissalTransitionWillBegin() {
		swizzled_dismissalTransitionWillBegin()
		additionalDismissalAnimation?()
	}

	@objc fileprivate dynamic func swizzled_presentationTransitionWillBegin() {
		swizzled_presentationTransitionWillBegin()
		additionalPresentationAnimation?()
	}
}

extension UIPresentationController {
	// runtime properties enabled by the obj-c runtime
	// ref: https://nshipster.com/associated-objects
	fileprivate var additionalPresentationAnimation: (() -> Void)? {
		get {
			let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
			return objc_getAssociatedObject(self, key) as? () -> Void
		}
		set {
			let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
			objc_setAssociatedObject(self, key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}

	// runtime properties enabled by the obj-c runtime
	// ref: https://nshipster.com/associated-objects
	fileprivate var additionalDismissalAnimation: (() -> Void)? {
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

// basic swizzling logic. could probably be generalised to be used anywhere else where needed.
extension UIPresentationController {
	fileprivate static var swizzledSelectors: [Selector: Void] = [:]

	fileprivate func swizzle(
		original originalSelector: Selector,
		swizzled swizzledSelector: Selector
	) {
		// ensures selector being swizzled hasn't been previously swizzled
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
