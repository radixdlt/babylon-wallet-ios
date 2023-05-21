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
	private let isSelected: Bool
	private let action: () -> Void

	public init(viewState: ViewState, isSelected: Bool, action: @escaping () -> Void) {
		self.viewState = viewState
		self.isSelected = isSelected
		self.action = action
	}

	public var body: some View {
		Button(action: action) {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					Text(viewState.description)
						.textStyle(.body1Header)

					HPair(label: L10n.CreateEntity.Ledger.usedHeading, item: viewState.lastUsedOn)

					HPair(label: L10n.CreateEntity.Ledger.addedHeading, item: viewState.addedOn)
				}

				Spacer()

				RadioButton(
					appearance: .light,
					state: isSelected ? .selected : .unselected
				)
			}
			.foregroundColor(.app.white)
			.padding(.medium1)
			.background(.black)
			.brightness(isSelected ? -0.1 : 0)
			.cornerRadius(.small1)
		}
		.buttonStyle(.inert)
	}
}
