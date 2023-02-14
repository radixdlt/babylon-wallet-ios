import FeaturePrelude

// MARK: - ConnectedDApps.View
public extension ConnectedDApps {
	@MainActor
	struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	internal struct ViewState: Equatable {
		let dApps: [DAppRowModel]
	}
}

// MARK: - Body

public extension ConnectedDApps.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: 0) {
					TextBlock(L10n.ConnectedDApps.body, textStyle: .body1HighImportance, color: .app.gray2)
						.padding(.vertical, .medium3)

					Separator()

					VStack(spacing: .medium3) {
						ForEach(viewStore.dApps) { dApp in
							RadixCard {
								PlainListRow(title: dApp.name) {
									viewStore.send(.didSelectDApp(dApp.name))
								} icon: {
									DAppPlaceholder()
								}
							}
						}
					}
					Spacer()
				}
				.padding(.horizontal, .medium3)
			}
			.navBarTitle(L10n.ConnectedDApps.title)
			.navigationDestination(store: store.selectedDApp) { store in
				DAppProfile.View(store: store)
			}
		}
	}
}

// MARK: - Extensions

private extension ConnectedDApps.Store {
	var selectedDApp: PresentationStoreOf<DAppProfile> {
		scope(state: \.$selectedDApp) { .child(.selectedDApp($0)) }
	}
}

private extension ConnectedDApps.State {
	var viewState: ConnectedDApps.ViewState {
		.init(dApps: dApps)
	}
}

// MARK: - RadixCard
public struct RadixCard<Contents: View>: View {
	private let contents: Contents

	public init(@ViewBuilder contents: () -> Contents) {
		self.contents = contents()
	}

	public var body: some View {
		HStack(spacing: 0) {
			contents
		}
		.cardStyle
	}
}

public extension View {
	var cardStyle: some View {
		background {
			RoundedRectangle(cornerRadius: .small1)
				.fill(.white)
				.radixShadow
		}
	}

	var radixShadow: some View {
		shadow(color: .app.gray2.opacity(0.26), radius: .medium3, x: .zero, y: .small2)
	}
}

// MARK: - RadixChevron
public struct RadixChevron: View {
	public var body: some View {
		Image(asset: AssetResource.chevronRight)
			.foregroundColor(.app.gray1)
			.padding(.trailing, 2)
	}
}
