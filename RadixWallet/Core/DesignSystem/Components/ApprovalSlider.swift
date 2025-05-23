// MARK: - ApprovalSlider
struct ApprovalSlider: View {
	private let title: String
	private let resetDate: Date
	private let action: () -> Void

	init(title: String, resetDate: Date, action: @escaping () -> Void) {
		self.title = title
		self.resetDate = resetDate
		self.action = action
	}

	var body: some View {
		Core(title: title, action: action)
			.id(resetDate)
	}

	private struct Core: View {
		@Environment(\.controlState) private var controlState
		@State private var approved: Bool = false
		@State private var position: CGFloat = 0

		let title: String
		let action: () -> Void

		var body: some View {
			GeometryReader { proxy in
				let width = proxy.size.width - .approveSliderHeight
				ZStack {
					background

					Text(title)
						.textStyle(.body1Header)
						.foregroundColor(controlState.isDisabled ? .tertiaryText : .white)
						.opacity(textOpacity)

					if controlState.isDisabled {
						if approved {
							Color.tertiaryBackground
						}
					} else {
						Color.app.gradientPurple
							.opacity(triggeredOpacity)

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
			.animation(.interactiveSpring(), value: position)
		}

		private var background: Color {
			controlState.isDisabled ? .tertiaryBackground : .button
		}

		private var textOpacity: CGFloat {
			min(2 - 3 * position, 1)
		}

		private var triggeredOpacity: CGFloat {
			if approved {
				1
			} else if triggered {
				0.5
			} else {
				0
			}
		}

		private let padding: CGFloat = 2

		private func gradientMask(for width: CGFloat) -> some View {
			let xAdjustment: CGFloat = (approved ? 0 : 0.5 * .approveSliderHeight)
			let opacity: CGFloat = min(1.0, 2.0 * position)
			return Rectangle()
				.offset(x: (position - 1) * width - xAdjustment)
				.opacity(opacity)
		}

		private func handle(for width: CGFloat) -> some View {
			Circle()
				.fill(controlState.isDisabled ? .tertiaryText : .primaryBackground)
				.overlay {
					if controlState.isLoading {
						ProgressView()
					} else {
						ZStack {
							let showRadixIcon = triggered || approved
							Image(asset: AssetResource.chevronRight)
								.renderingMode(.template)
								.opacity(showRadixIcon ? 0 : 1)
								.rotationEffect(showRadixIcon ? .radians(0.5 * .pi) : .zero)
								.offset(y: showRadixIcon ? 4 : 0)
								.scaleEffect(showRadixIcon ? 1.2 : 1)
							Image(asset: AssetResource.radixIcon)
								.renderingMode(.template)
								.opacity(showRadixIcon ? 1 : 0)
								.rotationEffect(showRadixIcon ? .zero : .radians(-0.5 * .pi))
								.scaleEffect(showRadixIcon ? 1 : 0.8)
						}
					}
				}
				.foregroundColor(controlState.isDisabled ? .tertiaryBackground : .textButton)
				.padding(padding)
				.offset(x: (position - 0.5) * width)
				.gesture(drag(width: width))
		}

		private var triggered: Bool {
			position > triggerPosition
		}

		private let triggerPosition: CGFloat = 0.93

		private func drag(width: CGFloat) -> some Gesture {
			DragGesture(minimumDistance: 0)
				.onChanged { gesture in
					guard controlState.isEnabled else { return }
					position = max(0, min(gesture.translation.width / width, 1))
				}
				.onEnded { gesture in
					let now = gesture.translation.width
					let end = gesture.predictedEndTranslation.width
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
		.init(color: .gradientGreen3, location: 0),
		.init(color: .gradientBlue3, location: 0.41),
		.init(color: .gradientPink3, location: 0.81),
		.init(color: .gradientBlue3, location: 1),
	])
}
