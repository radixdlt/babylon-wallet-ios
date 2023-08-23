import Resources
import SwiftUI

// MARK: - ApprovalSlider
public struct ApprovalSlider: View {
	@Environment(\.controlState) private var controlState
	@State private var approved: Bool = false
	@State private var position: CGFloat = 0

	private let title: String
	private let action: () -> Void

	public init(title: String, action: @escaping () -> Void) {
		self.title = title
		self.action = action
	}

	public var body: some View {
		GeometryReader { proxy in
			let width = proxy.size.width - .approveSliderHeight
			ZStack {
				if controlState.isDisabled {
					Color.app.gray4
				} else {
					Color.app.blue2
				}

				Text(title)
					.textStyle(.body1Header)
					.foregroundColor(controlState.isDisabled ? .app.gray3 : .white)
					.opacity(approved ? 0 : 1)

				if !controlState.isDisabled {
					Color.app.gradientPurple
						.opacity(approved ? 1 : (triggered ? 0.5 : 0))

					LinearGradient(gradient: .approvalSlider, startPoint: .leading, endPoint: .trailing)
						.mask { gradientMask(for: width) }
				}

				handle(for: width)
			}
			.clipShape(Capsule(style: .circular))
		}
		.frame(height: .approveSliderHeight)
		.animation(.default, value: controlState)
		.animation(.default, value: triggered)
	}

	private var triggered: Bool {
		position > triggerPosition
	}

	private let triggerPosition: CGFloat = 0.93

	private let padding: CGFloat = 2

	private func gradientMask(for width: CGFloat) -> some View {
		Rectangle()
			.offset(.init(x: (position - 1) * width - (approved ? 0 : 0.5 * .approveSliderHeight), y: 0))
			.opacity(min(1.0, 2.0 * position))
	}

	private func handle(for width: CGFloat) -> some View {
		Circle()
			.fill(controlState.isDisabled ? .app.gray3 : .white)
			.overlay {
				switch controlState {
				case .enabled:
					Image(asset: AssetResource.radixIconWhite)
						.renderingMode(.template)
						.transition(transition)
				case .loading:
					ProgressView()
				case .disabled:
					Image(asset: AssetResource.chevronRight)
						.renderingMode(.template)
						.transition(transition)
				}
			}
			.foregroundColor(controlState.isDisabled ? .app.gray4 : .app.blue2)
			.padding(padding)
			.offset(x: (position - 0.5) * width)
			.gesture(drag(width: width))
	}

	private let transition: AnyTransition = .scale(scale: 0.8).combined(with: .opacity)

	private func drag(width: CGFloat) -> some Gesture {
		DragGesture(minimumDistance: 0)
			.onChanged { gesture in
				guard controlState.isEnabled else { return }
				position = max(0, min(gesture.translation.width / width, 1))
			}
			.onEnded { gesture in
				let now = gesture.translation.width
				let end = gesture.predictedEndTranslation.width
				withAnimation {
					// You can either throw the handle to the right, or drop it very close to the end
					if now > 0.7 * width && end > 1.5 * width || now > triggerPosition * width {
						position = 1
						approved = true
						action()
					} else {
						position = 0
					}
				}
			}
	}
}

private extension Gradient {
	static let approvalSlider: Gradient = .init(stops: [
		.init(color: .app.account11green, location: 0),
		.init(color: .app.blue2, location: 0.41),
		.init(color: .app.gradientPurple, location: 0.81),
		.init(color: .app.gradientPurple.opacity(0), location: 1),
	])
}
