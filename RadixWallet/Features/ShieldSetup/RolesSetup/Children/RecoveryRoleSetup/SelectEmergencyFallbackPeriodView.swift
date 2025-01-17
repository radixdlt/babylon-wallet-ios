// MARK: - SelectEmergencyFallbackPeriodView
struct SelectEmergencyFallbackPeriodView: View {
	@State var selectedPeriod: FallbackPeriod

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
					ForEach(FallbackPeriod.Unit.allCases, id: \.self) { unit in
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
		case set(FallbackPeriod)
	}
}

private extension FallbackPeriod.Unit {
	var title: String {
		switch self {
		case .days:
			L10n.ShieldWizardRecovery.Fallback.Days.label
		case .weeks:
			L10n.ShieldWizardRecovery.Fallback.Weeks.label
		}
	}
}

// MARK: - FallbackPeriod
// TODO: - Move to Sargon -
struct FallbackPeriod: Sendable, Equatable {
	var value: Int
	var unit: Unit

	var days: Int {
		switch self.unit {
		case .days:
			value
		case .weeks:
			value * Self.DAYS_IN_A_WEEK
		}
	}

	init(days: Int) {
		if days % Self.DAYS_IN_A_WEEK == 0 {
			value = days / Self.DAYS_IN_A_WEEK
			unit = .weeks
		} else {
			value = days
			unit = .days
		}
	}

	private static let DAYS_IN_A_WEEK = 7
}

// MARK: FallbackPeriod.Unit
extension FallbackPeriod {
	enum Unit: CaseIterable {
		case days
		case weeks

		var values: [Int] {
			switch self {
			case .days:
				Self.FALLBACK_PERIOD_DAYS
			case .weeks:
				Self.FALLBACK_PERIOD_WEEKS
			}
		}

		private static let FALLBACK_PERIOD_DAYS = Array(1 ... 14)
		private static let FALLBACK_PERIOD_WEEKS = Array(1 ... 4)
	}
}

// ------------------------------------------------------------------
