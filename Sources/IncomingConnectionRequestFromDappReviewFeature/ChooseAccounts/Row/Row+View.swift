import ComposableArchitecture
import DesignSystem
import SwiftUI

// MARK: - ChooseAccounts.Row.View
public extension ChooseAccounts.Row {
	struct View: SwiftUI.View {
		private let store: StoreOf<ChooseAccounts.Row>

		public init(store: StoreOf<ChooseAccounts.Row>) {
			self.store = store
		}
	}
}

public extension ChooseAccounts.Row.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: ChooseAccounts.Row.Action.init
		) { viewStore in
			HStack {
				VStack(alignment: .leading, spacing: 14) {
					Text(viewStore.accountName)
						.foregroundColor(.app.white)
						.textStyle(.body1Header)

					Text(viewStore.accountAddress)
						.foregroundColor(.app.white.opacity(0.8))
						.textStyle(.body2HighImportance)
				}

				Spacer()

				CheckmarkView(isChecked: viewStore.isSelected)
			}
			.padding(24)
			.background(
				LinearGradient.app.account1
					.brightness(viewStore.isSelected ? -0.1 : 0)
			)
			.cornerRadius(12)
			.onTapGesture {
				viewStore.send(.didSelect)
			}
		}
	}
}

// MARK: - ChooseAccounts.Row.View.ViewAction
extension ChooseAccounts.Row.View {
	enum ViewAction: Equatable {
		case didSelect
	}
}

extension ChooseAccounts.Row.Action {
	init(action: ChooseAccounts.Row.View.ViewAction) {
		switch action {
		case .didSelect:
			self = .internal(.user(.didSelect))
		}
	}
}

// MARK: - ChooseAccounts.Row.View.ViewState
extension ChooseAccounts.Row.View {
	struct ViewState: Equatable {
		let isSelected: Bool
		let accountName: String
		let accountAddress: String

		init(state: ChooseAccounts.Row.State) {
			isSelected = state.isSelected
			accountName = state.account.name
			accountAddress = state.account.address
		}
	}
}

// MARK: - Row_Preview
struct Row_Preview: PreviewProvider {
	static var previews: some View {
		registerFonts()

		return ChooseAccounts.Row.View(
			store: .init(
				initialState: .placeholder,
				reducer: ChooseAccounts.Row()
			)
		)
	}
}
