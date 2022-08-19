import ComposableArchitecture
import SwiftUI

public extension Home.AccountRow {
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

public extension Home.AccountRow.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Home.AccountRow.Action.init
			)
		) { _ in
			VStack(alignment: .leading) {
				VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("My main account")
                            .foregroundColor(.app.buttonTextBlack)
                            .font(.app.buttonTitle)
                            .fixedSize()
                        Spacer()
                        Text(amount)
                            .foregroundColor(.app.buttonTextBlack)
                            .font(.app.buttonTitle)
                            .fixedSize()
                    }

					HStack(spacing: 0) {
						Text("rdr12hj3cqqG89ijHsjA3cq2qgtxg4sahjU78s")
							.lineLimit(1)
							.truncationMode(.middle)
							.foregroundColor(.app.buttonTextBlackTransparent)
							.font(.app.caption2)
							.frame(maxWidth: 110)

						Button(
							action: {
								// TODO: implement address copy
							},
							label: {
								Text("Copy")
									.foregroundColor(.app.buttonTextBlack)
									.font(.app.caption2)
									.underline()
									.padding(12)
							}
						)
						Spacer()
					}
				}

				HStack(spacing: -10) {
					ForEach(0 ..< .random(in: 1 ... 10)) { _ in
						TokenView()
							.frame(width: 30, height: 30)
					}
				}
			}
			.padding(25)
			.background(Color.app.cardBackgroundLight)
			.cornerRadius(6)
		}
	}
    
    var amount: String {
        Float(100000).formatted(.currency(code: "USD"))
    }
}

extension Home.AccountRow.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension Home.AccountRow.Action {
	init(action: Home.AccountRow.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

extension Home.AccountRow.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Home.AccountRow.State) {
			// TODO: implement
		}
	}
}

// MARK: - TokenView
struct TokenView: View {
	var body: some View {
		ZStack {
			Circle()
				.strokeBorder(.orange, lineWidth: 1)
				.background(Circle().foregroundColor(Color.App.random))
			Text("Rdr")
				.textCase(.uppercase)
				.foregroundColor(.app.buttonTextBlack)
				.font(.app.footnote)
		}
	}
}

// MARK: - AccountRow_Preview
struct AccountRow_Preview: PreviewProvider {
	static var previews: some View {
		Home.AccountRow.View(
			store: .init(
				initialState: .placeholder,
				reducer: Home.AccountRow.reducer,
				environment: .init()
			)
		)
	}
}
