import FeaturePrelude
import FungibleTokenListFeature
import NonFungibleTokenListFeature

// MARK: - AssetsView.View
extension AssetsView {
	@MainActor
	public struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension AssetsView.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			VStack(spacing: .large3) {
				selectorView(with: viewStore)
					.padding([.top, .horizontal], .medium1)

				switch viewStore.state.type {
				case .tokens:
					FungibleTokenList.View(
						store: store.scope(
							state: \.fungibleTokenList,
							action: { .child(.fungibleTokenList($0)) }
						)
					)
				case .nfts:
					NonFungibleTokenList.View(
						store: store.scope(
							state: \.nonFungibleTokenList,
							action: { .child(.nonFungibleTokenList($0)) }
						)
					)

					// TODO: uncomment when ready for implementation
					/*
					 case .poolShare:
					 	Text("Pool Share")
					 case .badges:
					 	Text("Badges")
					 */
				}
			}
		}
	}
}

// MARK: - AssetsView.View.AssetsViewViewStore
extension AssetsView.View {
	fileprivate typealias AssetsViewViewStore = ComposableArchitecture.ViewStore<AssetsView.View.ViewState, AssetsView.ViewAction>
}

// MARK: - Private Methods
extension AssetsView.View {
	fileprivate func selectorView(with viewStore: AssetsViewViewStore) -> some View {
		HStack(spacing: .zero) {
			Spacer()

			ForEach(AssetsView.AssetsViewType.allCases) { type in
				selectorButton(type: type, with: viewStore) {
					viewStore.send(.listSelectorTapped(type))
				}
			}

			Spacer()
		}
	}

	fileprivate func selectorButton(
		type: AssetsView.AssetsViewType,
		with viewStore: AssetsViewViewStore,
		action: @escaping () -> Void
	) -> some View {
		Text(type.displayText)
			.foregroundColor(type == viewStore.type ? .app.white : .app.gray1)
			.textStyle(.body1HighImportance)
			.frame(height: .large1)
			.padding(.horizontal, .medium2)
			.background(type == viewStore.type ?
				RoundedRectangle(cornerRadius: .medium2)
				.fill(Color.app.gray1) : nil
			)
			.id(type)
			.onTapGesture {
				action()
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

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct AssetsView_Preview: PreviewProvider {
	static var previews: some View {
		AssetsView.View(
			store: .init(
				initialState: .init(
					fungibleTokenList: .init(sections: []),
					nonFungibleTokenList: .init(rows: [])
				),
				reducer: AssetsView()
			)
		)
	}
}
#endif
