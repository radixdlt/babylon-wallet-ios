import SwiftUI

// MARK: - SecurityStructureOfFactorSourcesView.View
struct SecurityStructureOfFactorSourcesView: View {
	let structure: SecurityStructureOfFactorSources

	var body: some SwiftUI.View {
		VStack(spacing: .medium3) {
			primaryRoleFactors
			performShieldRecoveryFactors
		}
		.padding(.vertical, .medium3)
		.background(.secondaryBackground)
	}

	private func sectionHeader(
		title: String? = nil,
		description: String? = nil,
		note: String? = nil
	) -> some SwiftUI.View {
		VStack(alignment: .leading, spacing: .small2) {
			if let title {
				Text(title)
					.textStyle(.body1Header)
					.foregroundStyle(.primaryText)
			}

			if let description {
				Text(description)
					.textStyle(.body2Regular)
					.foregroundStyle(.secondaryText)
					.padding(.bottom, .small2)
			}

			if let note {
				Text(markdown: note, emphasizedColor: .primaryText, emphasizedFont: .app.body2Header)
					.multilineTextAlignment(.leading)
					.textStyle(.body2Regular)
					.foregroundStyle(.primaryText)
			}
		}
		.multilineTextAlignment(.leading)
		.flushedLeft
	}

	@ViewBuilder
	private var primaryRoleFactors: some SwiftUI.View {
		VStack(spacing: .medium3) {
			sectionHeader(
				title: L10n.TransactionReview.UpdateShield.regularAccessTitle,
				description: L10n.TransactionReview.UpdateShield.regularAccessMessage,
				note: L10n.TransactionReview.UpdateShield.primaryThersholdMessage(structure.matrixOfFactors.primaryRole.threshold.titleShort.uppercased())
			)

			factorsList(structure.matrixOfFactors.primaryRole.thresholdFactors)

			if !structure.matrixOfFactors.primaryRole.overrideFactors.isEmpty {
				sectionHeader(
					note: L10n.TransactionReview.UpdateShield.primaryOverrideMessage
				)

				factorsList(structure.matrixOfFactors.primaryRole.overrideFactors, combinationLabel: L10n.TransactionReview.UpdateShield.combinationLabel)
			}

			authenticationSigningFactor(structure.authenticationSigningFactor)
		}
		.padding(.horizontal, .medium3)
		Separator()
	}

	private func authenticationSigningFactor(_ factorSource: FactorSource) -> some SwiftUI.View {
		VStack(spacing: .medium3) {
			sectionHeader(
				title: L10n.TransactionReview.UpdateShield.authSigningTitle,
				description: L10n.TransactionReview.UpdateShield.authSigningMessage,
				note: L10n.TransactionReview.UpdateShield.authSigningThreshold
			)

			factorsList([factorSource])
		}
	}

	private var performShieldRecoveryFactors: some SwiftUI.View {
		VStack(spacing: .medium3) {
			sectionHeader(
				title: L10n.TransactionReview.UpdateShield.startConfirmTitle,
				description: L10n.TransactionReview.UpdateShield.startConfirmMessage
			)

			Separator()
			recoveryRoleFactors
			Separator()
			confirmationRoleFactors
			Separator()
			confirmationDelay
		}
		.padding(.horizontal, .medium3)
	}

	private var recoveryRoleFactors: some SwiftUI.View {
		VStack(spacing: .medium3) {
			sectionHeader(
				title: L10n.TransactionReview.UpdateShield.startRecoveryTitle,
				note: L10n.TransactionReview.UpdateShield.nonPrimaryOverrideMessage
			)

			factorsList(structure.matrixOfFactors.recoveryRole.overrideFactors, combinationLabel: L10n.TransactionReview.UpdateShield.combinationLabel)
		}
	}

	private var confirmationRoleFactors: some SwiftUI.View {
		VStack(spacing: .medium3) {
			sectionHeader(
				title: L10n.TransactionReview.UpdateShield.confirmRecoveryTitle,
				note: L10n.TransactionReview.UpdateShield.nonPrimaryOverrideMessage
			)

			factorsList(structure.matrixOfFactors.confirmationRole.overrideFactors, combinationLabel: L10n.TransactionReview.UpdateShield.combinationLabel)
		}
	}

	private func factorsList(_ factorSources: [FactorSource], combinationLabel: String? = nil) -> some SwiftUI.View {
		VStack(spacing: .small2) {
			ForEach(factorSources, id: \.self) { factorSource in
				FactorSourceCard(
					kind: .instance(
						factorSource: factorSource,
						kind: .short(showDetails: false)
					),
					mode: .display
				)

				let isLastFactor = factorSource == factorSources.last
				if let combinationLabel, !isLastFactor {
					Text(combinationLabel)
						.textStyle(.body1Link)
						.foregroundStyle(.primaryText)
				}
			}
		}
		.frame(maxWidth: .infinity)
	}

	private var confirmationDelay: some SwiftUI.View {
		VStack(spacing: .small1) {
			Text(L10n.TransactionReview.UpdateShield.confirmationDelayMessage)
				.textStyle(.body1Regular)
				.foregroundStyle(.black)
				.flushedLeft

			Label(structure.matrixOfFactors.timeUntilDelayedConfirmationIsCallable.title, asset: AssetResource.emergencyFallbackCalendar)
				.textStyle(.body1Link)
				.foregroundStyle(.black)
				.flushedLeft
				.padding(.horizontal, .medium3)
				.padding(.vertical, .medium3)
				.background(.white)
				.roundedCorners(strokeColor: .border, radius: .small2)
		}
		.padding(.medium3)
		.background(.app.lightError)
		.frame(maxWidth: .infinity)
		.roundedCorners(radius: .small1)
	}
}

//
// extension InteractionReview.ShieldView.ViewState {
//    private func filteredFactors(for roleFactors: KeyPath<MatrixOfFactorSourceIDs, [FactorSourceId]>) -> [FactorSource] {
//        allFactorSourcesFromProfile.filter { shield.matrixOfFactors[keyPath: roleFactors].contains($0.factorSourceID) }
//    }
//
//    var primaryThresholdFactors: [FactorSource] {
//        filteredFactors(for: \.primaryRole.thresholdFactors)
//    }
//
//    var primaryOverrideFactors: [FactorSource] {
//        filteredFactors(for: \.primaryRole.overrideFactors)
//    }
//
//    var recoveryFactors: [FactorSource] {
//        filteredFactors(for: \.recoveryRole.overrideFactors)
//    }
//
//    var confirmationFactors: [FactorSource] {
//        filteredFactors(for: \.confirmationRole.overrideFactors)
//    }
//
//    var authenticationSigningFactor: FactorSource? {
//        allFactorSourcesFromProfile.first { $0.factorSourceID == shield.authenticationSigningFactor }
//    }
//
//    var periodUntilAutoConfirm: TimePeriod {
//        shield.matrixOfFactors.timeUntilDelayedConfirmationIsCallable
//    }
//
//    var threshold: Threshold {
//        shield.matrixOfFactors.primaryRole.threshold
//    }
//
//    var shieldName: DisplayName {
//        shield.metadata.displayName
//    }
// }
