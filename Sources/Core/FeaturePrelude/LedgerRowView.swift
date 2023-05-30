import DesignSystem
import Profile
import SwiftUI

// MARK: - LedgerRowView
@MainActor
public struct LedgerRowView: View {
	public struct ViewState: Equatable {
		let description: String
		let addedOn: String
		let lastUsedOn: String

		public init(factorSource: LedgerHardwareWalletFactorSource) {
			self.description = "\(factorSource.hint.name.rawValue) (\(factorSource.hint.name.rawValue))"
			self.addedOn = factorSource.addedOn.ISO8601Format(.iso8601Date(timeZone: .current))
			self.lastUsedOn = factorSource.lastUsedOn.ISO8601Format(.iso8601Date(timeZone: .current))
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
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					Text(viewState.description)
						.textStyle(.body1Header)

					HPair(label: L10n.CreateEntity.Ledger.usedHeading, item: viewState.lastUsedOn)

					HPair(label: L10n.CreateEntity.Ledger.addedHeading, item: viewState.addedOn)
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
			.padding(.medium1)
		}
	}
}
