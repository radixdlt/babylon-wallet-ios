// MARK: - SelectNumberOfFactorsView
struct SelectNumberOfFactorsView: View {
	@State var selectedNumberOfFactors: Threshold
	let thresholdValues: [Threshold]

	var onAction: (Action) -> Void

	init(
		selectedNumberOfFactors: Threshold,
		thresholdValues: [Threshold],
		onAction: @escaping (Action) -> Void
	) {
		self.thresholdValues = thresholdValues
		self.onAction = onAction

		if thresholdValues.contains(selectedNumberOfFactors) {
			self.selectedNumberOfFactors = selectedNumberOfFactors
		} else {
			self.selectedNumberOfFactors = thresholdValues.first ?? selectedNumberOfFactors
		}
	}

	var body: some SwiftUI.View {
		content
			.withNavigationBar {
				onAction(.close)
			}
			.footer {
				Button(L10n.ShieldWizardRegularAccess.SetThreshold.button) {
					onAction(.set(selectedNumberOfFactors))
				}
				.buttonStyle(.primaryRectangular)
			}
			.presentationDetents([.fraction(0.65)])
			.presentationDragIndicator(.hidden)
			.presentationBackground(.blur)
	}

	private var content: some View {
		VStack {
			Text(L10n.ShieldWizardRegularAccess.SetThreshold.title)
				.textStyle(.sectionHeader)
				.foregroundStyle(.primaryText)
				.multilineTextAlignment(.center)

			Picker("", selection: $selectedNumberOfFactors) {
				ForEach(thresholdValues, id: \.self) { threshold in
					Text(threshold.title)
						.tag(threshold)
						.foregroundStyle(.primaryText)
						.textStyle(.body1Regular)
				}
			}
			.pickerStyle(.wheel)

			Spacer()
		}
		.padding(.horizontal, .large2)
	}
}

// MARK: SelectNumberOfFactorsView.Action
extension SelectNumberOfFactorsView {
	enum Action: Sendable, Hashable {
		case close
		case set(Threshold)
	}
}

private extension Threshold {
	var title: String {
		switch self {
		case .all:
			L10n.ShieldWizardRegularAccess.SetThreshold.all
		case let .specific(value):
			"\(value)"
		}
	}
}
