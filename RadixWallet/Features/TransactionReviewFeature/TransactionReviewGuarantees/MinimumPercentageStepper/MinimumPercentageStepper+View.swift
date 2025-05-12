import ComposableArchitecture
import SwiftUI

// MARK: - MinimumPercentageStepper.View
extension MinimumPercentageStepper {
	struct View: SwiftUI.View {
		private let store: StoreOf<MinimumPercentageStepper>
		private let title: String
		private let vertical: Bool

		init(
			store: StoreOf<MinimumPercentageStepper>,
			title: String = L10n.TransactionReview.Guarantees.setGuaranteedMinimum,
			vertical: Bool = false
		) {
			self.store = store
			self.title = title
			self.vertical = vertical
		}

		var body: some SwiftUI.View {
			let layout = vertical
				? AnyLayout(VStackLayout(spacing: .medium3))
				: AnyLayout(HStackLayout(spacing: .medium3))

			layout {
				Text(title)
					.lineLimit(2)
					.textStyle(.body2Header)
					.foregroundColor(.primaryText)

				if !vertical {
					Spacer(minLength: 0)
				}

				MinimumPercentageStepper.CoreView(store: store, expands: vertical)
			}
		}
	}

	struct CoreView: SwiftUI.View {
		private let store: StoreOf<MinimumPercentageStepper>
		private let expands: Bool

		init(store: StoreOf<MinimumPercentageStepper>, expands: Bool = false) {
			self.store = store
			self.expands = expands
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				HStack(spacing: .medium3) {
					let buttonPadding: CGFloat = expands ? .medium3 : .zero
					Button(asset: AssetResource.minusCircle) {
						viewStore.send(.decreaseTapped)
					}
					.opacity(viewStore.disableMinus ? disabledOpacity : 1)
					.disabled(viewStore.disableMinus)
					.padding(.horizontal, buttonPadding)

					let text = viewStore.binding(get: \.string) { .stringEntered($0) }
					TextField("", text: text)
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.center)
						.lineLimit(1)
						.textStyle(.body2Regular)
						.foregroundColor(.primaryText)
						.frame(width: expands ? nil : textFieldSize.width, height: textFieldSize.height)
						.background {
							RoundedRectangle(cornerRadius: 8)
								.fill(Color.tertiaryBackground)
							RoundedRectangle(cornerRadius: 8)
								.stroke(viewStore.isValid ? .app.gray4 : transparentErrorRed)
						}

					Button(asset: AssetResource.plusCircle) {
						viewStore.send(.increaseTapped)
					}
					.padding(.horizontal, buttonPadding)
				}
			}
		}

		private let disabledOpacity: CGFloat = 0.2

		private let transparentErrorRed: Color = .error.opacity(0.6)

		private let textFieldSize: CGSize = .init(width: 68, height: 48)
	}
}
