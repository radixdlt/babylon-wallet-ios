import Sargon
import SwiftUI

// MARK: - ShieldCard
struct ShieldCard: View {
	let shield: ShieldForDisplay
	let mode: Mode

	var body: some View {
		card
	}

	private var card: some View {
		HStack(spacing: .small2) {
			Image(shield.status.image)
				.resizable()
				.frame(iconSize)
				.padding(.vertical, iconVerticalPadding)

			VStack(alignment: .leading, spacing: .small2) {
				Text(shield.name.rawValue)
					.textStyle(.body1Header)
					.foregroundStyle(.app.gray1)

				if mode == .display {
					displayInfo
				}
			}

			Spacer()

			if case let .selection(isSelected) = mode {
				RadioButton(
					appearance: .dark,
					state: isSelected ? .selected : .unselected
				)
			}
		}
		.padding(.vertical, verticalPadding)
		.padding(.leading, .medium2)
		.padding(.trailing, .medium3)
		.background(.app.white)
		.roundedCorners(radius: .small1)
		.cardShadow
	}

	private var displayInfo: some SwiftUI.View {
		VStack(alignment: .leading, spacing: .small2) {
			VStack(alignment: .leading, spacing: .zero) {
				Text("Assigned to:")
					.textStyle(.body2HighImportance)

				Text("None")
					.textStyle(.body2Regular)
			}
			.foregroundStyle(.app.gray2)

			if let statusMessage = shield.status.statusMessageInfo {
				StatusMessageView(
					text: statusMessage.text,
					type: statusMessage.type,
					useNarrowSpacing: true,
					useSmallerFontSize: true
				)
			}
		}
	}
}

// MARK: ShieldCard.Mode
extension ShieldCard {
	enum Mode: Equatable, Sendable {
		case display
		case selection(isSelected: Bool)
	}
}

private extension ShieldCard {
	var verticalPadding: CGFloat {
		switch mode {
		case .display:
			.medium2
		case .selection:
			.medium3
		}
	}

	var iconVerticalPadding: CGFloat {
		switch mode {
		case .display:
			.small2
		case .selection:
			.zero
		}
	}

	var iconSize: HitTargetSize {
		switch mode {
		case .display:
			.large
		case .selection:
			.slightlySmaller
		}
	}
}

// MARK: - ShieldCardStatus
// TODO: define in Sargon ------------------
enum ShieldCardStatus {
	case applied
	case actionRequired
	case notApplied
}

// -----------------------------------------

private extension ShieldCardStatus {
	var image: ImageResource {
		switch self {
		case .applied:
			.shieldStatusApplied
		case .actionRequired:
			.shieldStatusActionRequired
		case .notApplied:
			.shieldStatusNotApplied
		}
	}

	var statusMessageInfo: ShieldStatusMessageInfo? {
		switch self {
		case .applied:
			.general(type: .success, text: "Applied and working")
		case .actionRequired:
			.general(type: .warning, text: "Action required")
		case .notApplied:
			nil
		}
	}
}
