import FeaturePrelude

// MARK: - MinimumPercentageStepperView

extension MinimumPercentageStepper.State {
	var isValid: Bool {
		value != nil
	}
}

// MARK: - MinimumPercentageStepper.View
extension MinimumPercentageStepper {
	public struct View: SwiftUI.View {
		public let store: StoreOf<MinimumPercentageStepper>

		public init(store: StoreOf<MinimumPercentageStepper>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				HStack(spacing: .medium3) {
					Button(asset: AssetResource.minusCircle) {
						viewStore.send(.decreaseTapped)
					}
					.opacity(viewStore.disableMinus ? disabledOpacity : 1)
					.disabled(viewStore.disableMinus)

					let text = viewStore.binding(get: \.string) { .stringEntered($0) }
					TextField("", text: text)
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.center)
						.lineLimit(1)
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray1)
						.frame(width: textFieldSize.width, height: textFieldSize.height)
						.background {
							RoundedRectangle(cornerRadius: 8)
								.fill(.app.gray5)
							RoundedRectangle(cornerRadius: 8)
								.stroke(viewStore.isValid ? .app.gray4 : transparentErrorRed)
						}

					Button(asset: AssetResource.plusCircle) {
						viewStore.send(.increaseTapped)
					}
				}
			}
		}

		private let disabledOpacity: CGFloat = 0.2

		private let transparentErrorRed: Color = .app.red1.opacity(0.6)

		private let textFieldSize: CGSize = .init(width: 68, height: 48)
	}
}
