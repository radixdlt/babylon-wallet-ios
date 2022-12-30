import Common
import ComposableArchitecture
import DesignSystem
import Profile
import SwiftUI

// MARK: - ChooseAccounts.Row.View
public extension ChooseAccounts.Row {
	@MainActor
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
			send: { .view($0) }
		) { viewStore in
			HStack {
				VStack(alignment: .leading, spacing: .medium3) {
					Text(viewStore.accountName)
						.foregroundColor(.app.white)
						.textStyle(.body1Header)

					AddressView(viewStore.accountAddress, copyAddressAction: .none)
						.foregroundColor(.app.white.opacity(0.8))
						.textStyle(.body2HighImportance)
				}

				Spacer()

				CheckmarkView(isChecked: viewStore.isSelected)
			}
			.padding(.medium1)
			.background(
				viewStore.appearanceID.gradient
					.brightness(viewStore.isSelected ? -0.1 : 0)
			)
			.cornerRadius(.small1)
			.onTapGesture {
				viewStore.send(.didSelect)
			}
		}
	}
}

// MARK: - ChooseAccounts.Row.View.ViewState
extension ChooseAccounts.Row.View {
	struct ViewState: Equatable {
		let appearanceID: OnNetwork.Account.AppearanceID
		let isSelected: Bool
		let accountName: String
		let accountAddress: AddressView.ViewState

		init(state: ChooseAccounts.Row.State) {
			appearanceID = state.account.appearanceID
			isSelected = state.isSelected
			accountName = state.account.displayName ?? L10n.DApp.ChooseAccounts.unnamedAccount
			accountAddress = .init(address: state.account.address.address, format: .short())
		}
	}
}

#if DEBUG
struct Row_Preview: PreviewProvider {
	static var previews: some View {
		ChooseAccounts.Row.View(
			store: .init(
				initialState: .previewValueOne,
				reducer: ChooseAccounts.Row()
			)
		)
	}
}
#endif
