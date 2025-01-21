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

			MultiPickerView(
				data: [
					selectedPeriod.unit.values.map { "\($0)" },
					TimePeriodUnit.allCases.map(\.title),
				],
				selections: Binding(
					get: {
						[
							selectedPeriod.unit.values.firstIndex(of: Int(selectedPeriod.value)) ?? 0,
							TimePeriodUnit.allCases.firstIndex(of: selectedPeriod.unit) ?? 0,
						]
					},
					set: { newSelections in
						selectedPeriod.value = UInt16(selectedPeriod.unit.values[newSelections[0]])
						selectedPeriod.unit = TimePeriodUnit.allCases[newSelections[1]]
					}
				)
			)
			.frame(height: 200)

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
			L10n.ShieldWizardRecovery.Fallback.Years.label
		}
	}
}

// MARK: - TimePeriodUnit + CaseIterable
extension TimePeriodUnit: CaseIterable {
	public static let allCases: [Self] = [.days, .weeks, .years]
}
