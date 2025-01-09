// MARK: - SelectNumberOfFactorsView
struct SelectNumberOfFactorsView: View {
	@State var selectedNumberOfFactors: Threshold
	let maxAvailableFactors: Int

	var onAction: (Action) -> Void

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
				.foregroundStyle(.app.gray1)
				.multilineTextAlignment(.center)

			Picker("", selection: $selectedNumberOfFactors) {
				ForEach(pickerItems, id: \.self) { threshold in
					Text(threshold.title)
						.tag(threshold)
				}
			}
			.pickerStyle(.wheel)

			Spacer()
		}
		.padding(.horizontal, .large2)
	}

	private var pickerItems: [Threshold] {
		var values: [Threshold] = []

		for i in 1 ..< maxAvailableFactors {
			values.insert(.specific(i), at: 0)
		}

		values.insert(.all, at: 0)

		return values
	}
}

// MARK: SelectNumberOfFactorsView.Action
extension SelectNumberOfFactorsView {
	enum Action: Sendable, Hashable {
		case close
		case set(Threshold)
	}
}

// MARK: - Threshold
// TODO: Move to Sargon - https://radixdlt.atlassian.net/browse/ABW-4047
enum Threshold: Hashable {
	case all
	case specific(Int)
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
