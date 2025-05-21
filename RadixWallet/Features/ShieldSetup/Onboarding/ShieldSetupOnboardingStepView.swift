import SwiftUI

// MARK: - ShieldSetupOnboardingStepView
struct ShieldSetupOnboardingStepView: View {
	let step: ShieldSetupOnboardingStep

	var body: some View {
		ScrollView {
			VStack(spacing: .medium1) {
				Image(step.image)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.centered
					.padding(.bottom, .small3)

				VStack(spacing: .medium2) {
					Text(step.title)
						.textStyle(.sheetTitle)

					Text(step.subtitle)
						.textStyle(.body1Regular)

					if let (item, label) = step.infoLink {
						InfoButton(item, label: label)
					}
				}
				.foregroundStyle(.primaryText)
				.multilineTextAlignment(.center)
				.padding(.horizontal, .large2)

				Spacer()
			}
		}
	}
}

// MARK: - ShieldSetupOnboardingStep
enum ShieldSetupOnboardingStep: CaseIterable {
	case intro
	case buildShield
	case applyShield
}

extension ShieldSetupOnboardingStep {
	var image: ImageResource {
		switch self {
		case .intro:
			.shieldSetupOnboardingIntro
		case .buildShield:
			.shieldSetupOnboardingBuild
		case .applyShield:
			.shieldSetupOnboardingApply
		}
	}

	var title: String {
		typealias S = L10n.ShieldSetupOnboarding
		switch self {
		case .intro:
			return S.IntroStep.title
		case .buildShield:
			return S.BuildShieldStep.title
		case .applyShield:
			return S.ApplyShieldStep.title
		}
	}

	var subtitle: String {
		typealias S = L10n.ShieldSetupOnboarding
		switch self {
		case .intro:
			return S.IntroStep.subtitle
		case .buildShield:
			return S.BuildShieldStep.subtitle
		case .applyShield:
			return S.ApplyShieldStep.subtitle
		}
	}

	var infoLink: (item: InfoLinkSheet.GlossaryItem, label: String)? {
		switch self {
		case .intro:
			(.securityshields, L10n.InfoLink.Title.securityshields)
		case .buildShield:
			(.buildingshield, L10n.InfoLink.Title.buildingshield)
		case .applyShield:
			nil
		}
	}
}
