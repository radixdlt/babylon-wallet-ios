import SwiftUI

// MARK: - AnimationCompletionViewModifier
/// A view modifier allowing to observe the completion of a given value animation
public struct AnimationCompletionViewModifier<Value: Sendable & VectorArithmetic>: Animatable, ViewModifier {
	public typealias Observer = @MainActor @Sendable () -> Void
	public var animatableData: Value {
		didSet {
			guard animatableData == animatedValue else { return }
			Task { [observer] in
				await observer()
			}
		}
	}

	private let animatedValue: Value
	private let observer: Observer

	public init(animatedValue: Value, observer: @escaping Observer) {
		self.animatedValue = animatedValue
		self.animatableData = animatedValue
		self.observer = observer
	}

	public func body(content: Content) -> some View {
		content
	}
}

extension View {
	public func onAnimationCompleted<Value: Sendable & VectorArithmetic>(for animatedValue: Value, observer: @escaping AnimationCompletionViewModifier.Observer) -> some View {
		modifier(AnimationCompletionViewModifier(animatedValue: animatedValue, observer: observer))
	}
}
