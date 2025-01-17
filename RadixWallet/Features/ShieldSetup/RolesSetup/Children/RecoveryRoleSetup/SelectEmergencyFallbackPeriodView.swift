// MARK: - SelectEmergencyFallbackPeriodView
struct SelectEmergencyFallbackPeriodView: View {
	@State var selectedPeriod: TimePeriod

	var onAction: (Action) -> Void

	var body: some SwiftUI.View {
		content
			.withNavigationBar {
				onAction(.close)
			}
			.footer {
				Button(L10n.ShieldWizardRecovery.SetFallback.button) {
					onAction(.set(selectedPeriod))
				}
				.buttonStyle(.primaryRectangular)
			}
			.presentationDetents([.fraction(0.7)])
			.presentationDragIndicator(.hidden)
			.presentationBackground(.blur)
	}

	private var content: some View {
		VStack(spacing: .small2) {
			Text(L10n.ShieldWizardRecovery.SetFallback.title)
				.textStyle(.sectionHeader)
				.foregroundStyle(.app.gray1)

			Text(
				markdown: L10n.ShieldWizardRecovery.SetFallback.subtitle,
				emphasizedColor: .app.gray1,
				emphasizedFont: .app.body2Header
			)
			.textStyle(.body2Regular)
			.foregroundStyle(.app.gray1)

			HStack(spacing: 0) {
				Picker("", selection: $selectedPeriod.value) {
					ForEach(selectedPeriod.unit.values, id: \.self) { value in
						Text("\(value)")
							.tag(value)
							.foregroundStyle(.app.gray1)
							.textStyle(.body1Regular)
							.padding(.trailing, .large2)
							.flushedRight
					}
				}
				.pickerStyle(.wheel)
				.clipShape(.rect.offset(x: -.medium3))
				.padding(.trailing, -.medium3)

				Picker("", selection: $selectedPeriod.unit) {
					ForEach(TimePeriodUnit.allCases, id: \.self) { unit in
						Text("\(unit.title)")
							.tag(unit)
							.foregroundStyle(.app.gray1)
							.textStyle(.body1Regular)
							.padding(.leading, .medium3)
							.flushedLeft
					}
				}
				.pickerStyle(.wheel)
				.clipShape(.rect.offset(x: .medium3))
				.padding(.leading, -.medium3)
			}

			Spacer()
		}
		.padding(.horizontal, .large2)
		.multilineTextAlignment(.center)
	}
}

// MARK: SelectEmergencyFallbackPeriodView.Action
extension SelectEmergencyFallbackPeriodView {
	enum Action: Sendable, Equatable {
		case close
		case set(TimePeriod)
	}
}

private extension TimePeriodUnit {
	var title: String {
		switch self {
		case .days:
			L10n.ShieldWizardRecovery.Fallback.Days.label
		case .weeks:
			L10n.ShieldWizardRecovery.Fallback.Weeks.label
		case .years:
			// TODO:
			"L10n.ShieldWizardRecovery.Fallback.Years.label"
		}
	}
}

// MARK: - TimePeriodUnit + CaseIterable
extension TimePeriodUnit: CaseIterable {
	public static let allCases: [Self] = [.days, .weeks, .years]
}
