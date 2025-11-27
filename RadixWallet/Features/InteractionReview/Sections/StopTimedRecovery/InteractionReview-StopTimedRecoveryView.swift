import Sargon
import SwiftUI

extension InteractionReview {
	typealias StopTimedRecoveryState = StopTimedRecoveryView.ViewState

	struct StopTimedRecoveryView: View {
		let viewState: ViewState

		var body: some View {
			Card {
				InnerCard {
					coreView
				}
				.padding(.small1)
			}
		}

		@ViewBuilder
		private var coreView: some SwiftUI.View {
			entityCard

			HStack(spacing: .medium3) {
				Image(.close)
				Text(L10n.TransactionReview.StopTimedRecovery.message)
					.lineSpacing(-.small3)
					.textStyle(.body1HighImportance)
					.foregroundColor(.primaryText)
					.multilineTextAlignment(.leading)
			}
			.flushedLeft
			.padding(.horizontal, .medium3)
			.padding(.vertical, .medium2)
			.background(.secondaryBackground)
		}

		@ViewBuilder
		private var entityCard: some SwiftUI.View {
			switch viewState.entity {
			case let .accountEntity(account):
				AccountCard(kind: .innerCompact, account: account)
			case let .personaEntity(persona):
				HStack(alignment: .center, spacing: .medium3) {
					Image(.persona)
						.resizable()
						.frame(.small)

					Text(persona.displayName.rawValue)
						.textStyle(.secondaryHeader)
						.foregroundStyle(.primaryText)
						.flushedLeft
				}
				.padding(.horizontal, .medium1)
				.padding(.vertical, .small1)
				.roundedCorners(.top, strokeColor: .border, radius: .small1)
			}
		}
	}
}

// MARK: - InteractionReview.StopTimedRecoveryView.ViewState
extension InteractionReview.StopTimedRecoveryView {
	struct ViewState: Sendable, Hashable {
		let entity: AccountOrPersona
	}
}
