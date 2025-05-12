import Sargon

// MARK: - LedgerRowView
@MainActor
struct LedgerRowView: View {
	@Environment(\.colorScheme) private var colorScheme
	struct ViewState: Equatable {
		let description: String
		let addedOn: Date
		let lastUsedOn: Date

		init(factorSource: LedgerHardwareWalletFactorSource) {
			self.description = factorSource.hint.label
			self.addedOn = factorSource.common.addedOn
			self.lastUsedOn = factorSource.common.lastUsedOn
		}
	}

	private let viewState: ViewState
	private let isSelected: Bool?
	private let action: (() -> Void)?

	/// Creates a tappable Ledger card. If `isSelected` is non-nil, the card will have a radio button.
	init(viewState: ViewState, isSelected: Bool? = nil, action: @escaping () -> Void) {
		self.viewState = viewState
		self.isSelected = isSelected
		self.action = action
	}

	/// Creates an inert Ledger card, with no selection indication.
	init(viewState: ViewState) {
		self.viewState = viewState
		self.isSelected = nil
		self.action = nil
	}

	var body: some View {
		Card(action: action) {
			HStack(spacing: 0) {
				VStack(alignment: .leading, spacing: 0) {
					Text(viewState.description)
						.foregroundColor(.primaryText)
						.textStyle(.secondaryHeader)
						.padding(.bottom, .small1)

					LabelledDate(label: L10n.LedgerHardwareDevices.usedHeading, date: viewState.lastUsedOn)
						.padding(.bottom, .small3)

					LabelledDate(label: L10n.LedgerHardwareDevices.addedHeading, date: viewState.addedOn)
				}

				Spacer(minLength: 0)

				if let isSelected {
					RadioButton(
						appearance: colorScheme == .light ? .dark : .light,
						isSelected: isSelected
					)
				}
			}
			.foregroundColor(.primaryText)
			.padding(.horizontal, .large3)
			.padding(.vertical, .medium1)
		}
	}
}
