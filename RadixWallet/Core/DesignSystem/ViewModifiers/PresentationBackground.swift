import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

// MARK: - PresentationBackground
enum PresentationBackground {
	case blur(style: UIBlurEffect.Style)

	static let blur: Self = .blur(style: .systemUltraThinMaterialDark)
}

extension View {
	func presentationBackground(_ background: PresentationBackground) -> some View {
		self.modifier(PresentationBackgroundModifier(background: background))
	}
}

// MARK: - PresentationBackgroundModifier
private struct PresentationBackgroundModifier: ViewModifier {
	let background: PresentationBackground

	func body(content: Content) -> some View {
		content
			// hands us the view controller corresponding to the SwiftUI view this modifier is attached
			// to as soon as it's added to its parent view/window
			.introspect(.sheet, on: .iOS(.v16...)) { (sheetPresentationController: UISheetPresentationController) in
				guard sheetPresentationController.additionalDismissalAnimation == nil else { return }

				let viewController = sheetPresentationController.presentedViewController

				guard
					let containerView = sheetPresentationController.containerView
				else {
					return
				}

				// disable standard background dimming altogether, as we're going to use our own
				sheetPresentationController.largestUndimmedDetentIdentifier = .large

				// Need to disable, since broken in swiftformat 0.52.7
				// swiftformat:disable redundantClosure

				// initialize background view and apply the chosen visual effects to it
				let backgroundView: UIView = {
					switch background {
					case let .blur(style):
						update(UIVisualEffectView(effect: UIBlurEffect(style: style))) {
							$0.frame = containerView.bounds
							$0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
						}
					}
				}()
				// swiftformat:enable redundantClosure

				backgroundView.alpha = 0
				// add the background view at the very back of the container hierarchy
				containerView.insertSubview(backgroundView, at: 0)

				// fade in background view alongside presentation animation
				viewController.transitionCoordinator?.animate(alongsideTransition: { _ in
					backgroundView.alpha = 1
				})

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

	@objc private dynamic func swizzled_presentationTransitionWillBegin() {
		swizzled_presentationTransitionWillBegin()
		additionalPresentationAnimation?()
	}
}

extension UIPresentationController {
	// runtime properties enabled by the obj-c runtime
	// ref: https://nshipster.com/associated-objects
	private var additionalPresentationAnimation: (() -> Void)? {
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
