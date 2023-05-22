import DesignSystem
import SwiftUI

// MARK: - LedgerRowView
@MainActor
public struct LedgerRowView: View {
	public struct ViewState: Equatable {
		let description: String
		let addedOn: String
		let lastUsedOn: String

		public init(factorSource: LedgerFactorSource) {
			self.description = "\(factorSource.label.rawValue) (\(factorSource.description.rawValue))"
			self.addedOn = factorSource.addedOn.ISO8601Format(.iso8601Date(timeZone: .current))
			self.lastUsedOn = factorSource.lastUsedOn.ISO8601Format(.iso8601Date(timeZone: .current))
		}
	}

	private let viewState: ViewState
	private let isSelected: Bool?
	private let action: (() -> Void)?

	/// If `isSelected` is non-nil, the card will have a radio button. If an action is supplied, it will be tappable.
	public init(viewState: ViewState, isSelected: Bool? = nil, action: (() -> Void)? = nil) {
		self.viewState = viewState
		self.isSelected = isSelected
		self.action = action
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
