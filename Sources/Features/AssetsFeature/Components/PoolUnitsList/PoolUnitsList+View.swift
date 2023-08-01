import FeaturePrelude

extension PoolUnitsList.State {
	var viewState: PoolUnitsList.ViewState {
		.init(
			isExpanded: isExpanded,
			lsuComponents: nil
		)
	}
}

// MARK: - LSUResourceViewState
struct LSUResourceViewState: Equatable {
	let iconURL: URL
	let name: String
}

// MARK: - PoolUnitsList.View
extension PoolUnitsList {
	public struct ViewState: Equatable {
		public var isExpanded: Bool
		let lsuResource: LSUResourceViewState

		let lsuComponents: NonEmpty<IdentifiedArrayOf<LSUComponent.ViewState>>?

		init(
			isExpanded: Bool,
			lsuComponents: NonEmpty<IdentifiedArrayOf<LSUComponent.ViewState>>?,
			lsuResource: LSUResourceViewState = .init(
				iconURL: .init(string: "www.wp.pl")!,
				name: "Radix Network XRD Stake"
			)
		) {
			self.isExpanded = isExpanded
			self.lsuComponents = lsuComponents
			self.lsuResource = lsuResource
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store<PoolUnitsList.ViewState, PoolUnitsList.ViewAction>

		public init(store: Store<PoolUnitsList.ViewState, PoolUnitsList.ViewAction>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ScrollView {
				IfLetStore(
					store.scope(
						state: \.lsuComponents,
						action: identity
					)
				) { lsuComponentsStore in
					WithViewStore(store, observe: \.isExpanded) { isExpandedViewStore in
						StackedViewsLayout(
							isExpanded: isExpandedViewStore.state,
							collapsedViewsCount: 2
						) {
							WithViewStore(
								store,
								observe: \.lsuResource
							) { lsuResourceViewStore in
								HStack(spacing: .medium2) {
									NFTThumbnail(lsuResourceViewStore.iconURL, size: .small)

									VStack(alignment: .leading) {
										// warning
										Text(lsuResourceViewStore.name ?? "")
											.foregroundColor(.app.gray1)
											.textStyle(.secondaryHeader)

										Text("3 Stakes")
											.foregroundColor(.app.gray2)
											.textStyle(.body2HighImportance)
									}

									Spacer()
								}
								.padding(.horizontal, .medium1)
								.background(.app.white)
								.roundedCorners(isExpandedViewStore.state ? .top : .allCorners, radius: .small1)
								.tokenRowShadow(!isExpandedViewStore.state)
							}
							.roundedCorners(
								isExpandedViewStore.state
									? .top
									: .allCorners,
								radius: .small1
							)
							.tokenRowShadow(!isExpandedViewStore.state)
							.padding(.medium1)
							.onTapGesture {
								isExpandedViewStore.send(.isExpandedToggled)
							}

							if isExpandedViewStore.state {
								ForEachStore(
									lsuComponentsStore.scope(
										state: \.rawValue,
										action: { _ in
											fatalError()
										}
									),
									content: LSUComponent.View.init
								)
							} else {
								Text("TEMP!")
							}
						}
					}
				}
			}
		}
	}
}
