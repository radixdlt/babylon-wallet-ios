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
				iconURL: .init(string: "https://i.ibb.co/KG06168/Screenshot-2023-08-02-at-16-19-29.png")!,
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
							collapsedViewsCount: 1
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
								.padding(.medium1)
								.background(.app.white)
								.roundedCorners(isExpandedViewStore.state ? .top : .allCorners, radius: .small1)
								.zIndex(.infinity)
								.roundedCorners(
									isExpandedViewStore.state
										? .top
										: .allCorners,
									radius: .small1
								)
								.tokenRowShadow(!isExpandedViewStore.state)
								.onTapGesture {
									isExpandedViewStore.send(.isExpandedToggled, animation: .easeInOut)
								}
							}

							if isExpandedViewStore.state {
								VStack {
									ForEachStore(
										lsuComponentsStore.scope(
											state: \.rawValue,
											action: { _ in
												fatalError()
											}
										),
										content: LSUComponent.View.init
									)
								}
							}

							GeometryReader { geometry in
								Spacer(
									minLength: isExpandedViewStore.state
										? .zero
										: 88
								)
								.padding(
									isExpandedViewStore.state
										? .zero
										: .medium1
								)
								.background(.app.white)
								.roundedCorners(
									.bottom,
									radius: .small1
								)
								.frame(width: geometry.size.width)
								.scaleEffect(0.95)
								.tokenRowShadow(!isExpandedViewStore.state)
							}
						}
						.padding(.medium1)
					}
				}
			}
		}
	}
}
