
// MARK: - LedgerRowView
@MainActor
public struct LedgerRowView: View {
	public struct ViewState: Equatable {
		let description: String
		let addedOn: Date
		let lastUsedOn: Date

		public init(factorSource: LedgerHardwareWalletFactorSource) {
			self.description = factorSource.hint.name
			self.addedOn = factorSource.addedOn
			self.lastUsedOn = factorSource.lastUsedOn
		}
	}

	private let viewState: ViewState
	private let isSelected: Bool?
	private let action: (() -> Void)?

	/// Creates a tappable Ledger card. If `isSelected` is non-nil, the card will have a radio button.
	public init(viewState: ViewState, isSelected: Bool? = nil, action: @escaping () -> Void) {
		self.viewState = viewState
		self.isSelected = isSelected
		self.action = action
	}

	/// Creates an inert Ledger card, with no selection indication.
	public init(viewState: ViewState) {
		self.viewState = viewState
		self.isSelected = nil
		self.action = nil
	}

	public var body: some View {
		Card(.app.gray5, action: action) {
			HStack(spacing: 0) {
				VStack(alignment: .leading, spacing: 0) {
					Text(viewState.description)
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)
						.padding(.bottom, .small1)

					LabelledDate(label: L10n.LedgerHardwareDevices.usedHeading, date: viewState.lastUsedOn)
						.padding(.bottom, .small3)

					LabelledDate(label: L10n.LedgerHardwareDevices.addedHeading, date: viewState.addedOn)
				}

				Spacer(minLength: 0)

				if let isSelected {
					RadioButton(
						appearance: .light,
						state: isSelected ? .selected : .unselected
					)
				}
			}
			.foregroundColor(.app.gray1)
			.padding(.horizontal, .large3)
			.padding(.vertical, .medium1)
		}
	}
}
