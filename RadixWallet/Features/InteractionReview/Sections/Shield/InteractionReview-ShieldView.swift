import Sargon
import SwiftUI

extension InteractionReview {
	typealias ShieldState = ShieldView.ViewState

	struct ShieldView: View {
		let viewState: ViewState

		var body: some View {
			Card {
				InnerCard {
					coreView
				}
				.padding(.small1)
			}
		}

		@MainActor
		@ViewBuilder
		private var coreView: some SwiftUI.View {
			entity
			SecurityStructureOfFactorSourcesView(structure: viewState.shield, onFactorSourceTapped: { _ in })
			//			VStack(spacing: .medium3) {
			//				// factorsHeader
			//				primaryRoleFactors
			//				performShieldRecoveryFactors
			//			}
			//			.padding(.vertical, .medium3)
			//			.background(.secondaryBackground)
		}

		@ViewBuilder
		private var entity: some SwiftUI.View {
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

// MARK: - InteractionReview.ShieldView.ViewState
extension InteractionReview.ShieldView {
	struct ViewState: Sendable, Hashable {
		let entity: AccountOrPersona
		let shield: SecurityStructureOfFactorSources
	}
}
