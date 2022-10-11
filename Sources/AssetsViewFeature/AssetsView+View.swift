import ComposableArchitecture
import FungibleTokenListFeature
import NonFungibleTokenListFeature
import SwiftUI

// MARK: - AssetsView.View
public extension AssetsView {
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

public extension AssetsView.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: AssetsView.Action.init
			)
		) { viewStore in
			VStack(spacing: 30) {
				selectorView(with: viewStore)

				switch viewStore.state.type {
				case .tokens:
					FungibleTokenList.View(
						store: store.scope(
							state: \.fungibleTokenList,
							action: AssetsView.Action.fungibleTokenList
						)
					)
				case .nfts:
					NonFungibleTokenList.View(
						store: store.scope(
							state: \.nonFungibleTokenList,
							action: AssetsView.Action.nonFungibleTokenList
						)
					)
				case .poolShare:
					Text("Pool Share")
				case .badges:
					Text("Badges")
				}
			}
		}
	}
}

// MARK: - AssetsView.View.AssetsViewViewStore
private extension AssetsView.View {
	typealias AssetsViewViewStore = ComposableArchitecture.ViewStore<AssetsView.View.ViewState, AssetsView.View.ViewAction>
}

// MARK: - Private Methods
private extension AssetsView.View {
	func selectorView(with viewStore: AssetsViewViewStore) -> some View {
		ScrollView(.horizontal, showsIndicators: false) {
			ScrollViewReader { proxy in
				HStack(spacing: 0) {
					ForEach(AssetsView.AssetsViewType.allCases) { type in
						selectorButton(type: type, with: viewStore) {
							viewStore.send(.listSelectorTapped(type))
							withAnimation {
								proxy.scrollTo(type, anchor: .center)
							}
						}
					}
				}
				.padding([.leading, .trailing], 18)
			}
		}
	}

	func selectorButton(
		type: AssetsView.AssetsViewType,
		with viewStore: AssetsViewViewStore,
		action: @escaping () -> Void
	) -> some View {
		Button(
			action: {
				action()
			}, label: {
				Text(type.displayText)
					.foregroundColor(type == viewStore.type ? .app.white : .app.buttonTextBlack)
					.textStyle(.body1Header)
					.frame(height: 40)
					.padding([.leading, .trailing], 18)
					.background(type == viewStore.type ?
						RoundedRectangle(cornerRadius: 21)
						.fill(Color.app.gray1) : nil
					)
			}
		)
		.id(type)
	}
}

// MARK: - AssetsView.View.ViewAction
extension AssetsView.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case listSelectorTapped(AssetsView.AssetsViewType)
	}
}

extension AssetsView.Action {
	init(action: AssetsView.View.ViewAction) {
		switch action {
		case let .listSelectorTapped(type):
			self = .internal(.user(.listSelectorTapped(type)))
		}
	}
}

// MARK: - AssetsView.View.ViewState
extension AssetsView.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		var type: AssetsView.AssetsViewType

		init(state: AssetsView.State) {
			type = state.type
		}
	}
}

// MARK: - AssetsView_Preview
struct AssetsView_Preview: PreviewProvider {
	static var previews: some View {
		AssetsView.View(
			store: .init(
				initialState: .init(
					fungibleTokenList: .init(sections: []),
					nonFungibleTokenList: .init(rows: [])
				),
				reducer: AssetsView.reducer,
				environment: .init()
			)
		)
	}
}
