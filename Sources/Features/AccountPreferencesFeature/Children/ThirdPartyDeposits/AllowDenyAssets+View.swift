import EngineKit
import FeaturePrelude

extension AllowDenyAssets.State {
	var viewState: AllowDenyAssets.ViewState {
		.init(
			selectedList: list,
			info: {
				switch list {
				case .allow where allowList.isEmpty:
					return "Add a specific asset by its resource address to allow all third-party deposits"
				case .deny where denyList.isEmpty:
					return "Add a specific asset by its resource address to deny all third-party deposits"
				case .allow where !allowList.isEmpty:
					return "The following resource addresses may always be deposited to this account by third parties."
				case .deny where !denyList.isEmpty:
					return "The following resource addresses may never be deposited to this account by third parties."
				default:
					return ""
				}
			}()
		)
	}
}

extension AllowDenyAssets {
	public struct ViewState: Equatable {
		let selectedList: State.List
		let info: String
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<AllowDenyAssets>
		init(store: StoreOf<AllowDenyAssets>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				VStack(spacing: .medium1) {
					Group {
						Picker(
							"What is your favorite color?",
							selection: viewStore.binding(get: \.selectedList, send: { .view(.listChanged($0)) })
						) {
							ForEach(State.List.allCases, id: \.self) {
								Text($0.text)
							}
						}
						.pickerStyle(.segmented)

						Text(viewStore.info)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray2)
							.multilineTextAlignment(.center)
					}
					.padding(.horizontal, .medium1)
					ResourcesList.View(store: store.scope(state: \.addressesList, action: { .child(.addressesList($0)) }))
				}
				.padding(.top, .medium1)
				.background(.app.gray5)
				.navigationTitle("Allow/Deny Specific Assets")
				.defaultNavBarConfig()
			}
		}
	}
}

extension AllowDenyAssets.State.List {
	var text: String {
		switch self {
		case .allow:
			return "Allow"
		case .deny:
			return "Deny"
		}
	}
}

extension DepositAddress {
	var ledgerIdentifiable: LedgerIdentifiable {
		switch self {
		case let .resource(address):
			return .address(.resource(address))
		case let .nftID(id):
			return .address(.nonFungibleGlobalID(id))
		}
	}
}
