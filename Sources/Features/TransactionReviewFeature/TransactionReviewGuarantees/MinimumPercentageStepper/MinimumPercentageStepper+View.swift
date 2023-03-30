import FeaturePrelude

// MARK: - MinimumPercentageStepperView

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
					.opacity(viewStore.disableMinus ? 0.2 : 1)
					.disabled(viewStore.disableMinus)

					let text = viewStore.binding(get: \.string) { .stringEntered($0) }
					TextField("", text: text)
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.center)
						.lineLimit(1)
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray1)
						.frame(width: 68, height: 48)
						.background {
							RoundedRectangle(cornerRadius: 8)
								.fill(.app.gray5)
							RoundedRectangle(cornerRadius: 8)
								.stroke(viewStore.isValid ? .app.gray4 : .app.red1.opacity(0.6))
						}

					Button(asset: AssetResource.plusCircle) {
						viewStore.send(.increaseTapped)
					}
					.opacity(viewStore.disablePlus ? 0.2 : 1)
					.disabled(viewStore.disablePlus)
				}
			}
		}
	}
}
