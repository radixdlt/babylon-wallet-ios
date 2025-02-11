import SwiftUI

// MARK: - OffDeviceMnemonicFactorSourceAccess.View
extension OffDeviceMnemonicFactorSourceAccess {
	struct View: SwiftUI.View {
		let store: StoreOf<OffDeviceMnemonicFactorSourceAccess>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(alignment: .leading, spacing: .medium3) {
					ImportMnemonicGrid.View(store: store.grid)
						.padding(.horizontal, -.small1)

					if let hint = store.hint {
						Hint(viewState: hint)
					}

					Button(L10n.Common.confirm) {
						store.send(.view(.confirmButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
					.controlState(store.confirmButtonControlState)
				}
			}
		}
	}
}

private extension StoreOf<OffDeviceMnemonicFactorSourceAccess> {
	var grid: StoreOf<ImportMnemonicGrid> {
		scope(state: \.grid, action: \.child.grid)
	}
}