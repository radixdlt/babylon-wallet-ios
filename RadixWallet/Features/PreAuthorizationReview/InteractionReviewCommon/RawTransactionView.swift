import SwiftUI

extension InteractionReviewCommon {
	struct RawTransactionView: SwiftUI.View {
		let transaction: String
		let copyAction: () -> Void
		let toggleAction: (() -> Void)?

		init(
			transaction: String,
			copyAction: @escaping () -> Void,
			toggleAction: (() -> Void)? = nil
		) {
			self.transaction = transaction
			self.copyAction = copyAction
			self.toggleAction = toggleAction
		}

		var body: some View {
			VStack(alignment: .leading, spacing: .medium1) {
				HStack(spacing: .small1) { // TODO: confirm spacing
					Spacer()
					copyButton
					toggleButton
				}

				content
					.padding(.horizontal, .small1)
			}
			.padding([.top, .horizontal], .medium3)
			.padding(.bottom, .medium1)
			.frame(maxWidth: .infinity)
		}

		private var copyButton: some View {
			Button(action: copyAction) {
				HStack(spacing: .small3) {
					AssetIcon(.asset(AssetResource.copy))
					Text(L10n.Common.copy)
						.textStyle(.body1Header)
				}
				.foregroundColor(.app.gray1)
			}
			.buttonStyle(.secondaryRectangular)
		}

		private var toggleButton: some View {
			Group {
				if let toggleAction {
					Button(asset: AssetResource.iconTxnBlocks, action: toggleAction)
						.buttonStyle(.secondaryRectangular)
				}
			}
		}

		private var content: some View {
			Text(transaction)
				.textStyle(.monospace)
				.foregroundColor(.app.gray1)
				.multilineTextAlignment(.leading)
				.textSelection(.enabled)
		}
	}
}
