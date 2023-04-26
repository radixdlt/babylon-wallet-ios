import SwiftUI

// MARK: - ShimmerModifier
/// A very basic horizontal shimmering animation based on the LinearGradient
public struct ShimmerModifier: ViewModifier {
	public struct Config {
		public typealias Location = (start: UnitPoint, end: UnitPoint)

		public let startLocation: Location
		public let endLocation: Location
		public let opacity: Double
		public let gradient: Gradient
		public let duration: Double

		public init(
			startLocation: Location,
			endLocation: Location,
			opacity: Double,
			gradient: Gradient,
			duration: Double
		) {
			self.startLocation = startLocation
			self.endLocation = endLocation
			self.opacity = opacity
			self.gradient = gradient
			self.duration = duration
		}
	}

	// MARK: - Config
	private let config: Config

	// MARK: - State
	@State private var startPoint: UnitPoint
	@State private var endPoint: UnitPoint

	public var isActive: Bool

	public init(
		isActive: Bool,
		config: Config
	) {
		self.config = config
		self.startPoint = config.startLocation.start
		self.endPoint = config.startLocation.end
		self.isActive = isActive
	}

	public func body(content: Content) -> some View {
		ZStack {
			content
			if isActive {
				LinearGradient(
					gradient: config.gradient,
					startPoint: startPoint,
					endPoint: endPoint
				)
				.opacity(config.opacity)
				.onAppear {
					withAnimation(Animation.linear(duration: config.duration).repeatForever(autoreverses: false)) {
						startPoint = config.endLocation.start
						endPoint = config.endLocation.end
					}
				}
			}
		}
	}
}

extension ShimmerModifier.Config {
	public static let accountResourcesLoading = Self(
		startLocation: (UnitPoint(x: -2, y: 0.5), UnitPoint.leading),
		endLocation: (UnitPoint.trailing, UnitPoint(x: 2, y: 0.5)),
		opacity: 0.5,
		gradient: Gradient(stops: [
			.init(color: .clear, location: 0),
			.init(color: .white, location: 0.33),
			.init(color: .white, location: 0.66),
			.init(color: .clear, location: 1),
		]),
		duration: 2
	)
}

extension View {
	/// Adds a basic shimmering animation to the view
	@ViewBuilder public func shimmer(active: Bool, config: ShimmerModifier.Config) -> some View {
		modifier(ShimmerModifier(isActive: active, config: config))
	}
}
