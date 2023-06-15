import AddFactorSourceFactorSourceFeature
import FeaturePrelude
import NewConnectionFeature
import Profile

extension FactorSourcesOfKindList.State {
	var viewState: FactorSourcesOfKindList.ViewState {
		.init(state: self)
	}
}

public extension FactorSourcesOfKindList {
	struct ViewState: Equatable {
		let allowSelection: Bool
		let showHeaders: Bool
		let factorSources: Loadable<IdentifiedArrayOf<FactorSourceOfKind>>
		let selectedFactorSourceID: FactorSourceID.FromHash?
		let selectedFactorSourceControlRequirements: SelectedFactorSourceControlRequirements?
		let context: State.Context

		init(state: FactorSourcesOfKindList.State) {
			allowSelection = state.allowSelection
			showHeaders = state.showHeaders
			factorSources = state.$factorSources
			selectedFactorSourceID = state.selectedFactorSourceID
			context = state.context

			if let id = state.selectedFactorSourceID, let selectedFactorSource = state.factorSources?[id: id] {
				selectedFactorSourceControlRequirements = .init(selectedFactorSource: selectedFactorSource)
			} else {
				selectedFactorSourceControlRequirements = nil
			}
		}

		var ledgersArray: [FactorSourceOfKind]? { .init(factorSources.wrappedValue ?? []) }

		var navigationTitle: String {
			if allowSelection {
				return L10n.FactorSourcesOfKindList.navigationTitleAllowSelection
			} else {
				return L10n.FactorSourcesOfKindList.navigationTitleGeneral
			}
		}

		var subtitle: String? {
			switch factorSources {
			case .idle, .loading:
				return nil
			case .failure:
				return L10n.FactorSourcesOfKindList.subtitleFailure
			case .success([]):
				return L10n.FactorSourcesOfKindList.subtitleNoFactorSources
			case .success:
				if allowSelection {
					return L10n.FactorSourcesOfKindList.subtitleSelectFactorSource
				} else {
					return L10n.FactorSourcesOfKindList.subtitleAllFactorSources
				}
			}
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<FactorSourcesOfKindList>

		public init(store: StoreOf<FactorSourcesOfKindList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: 0) {
						Group {
							if viewStore.context == .settings {
								Text(L10n.FactorSourcesOfKindList.subtitleAllFactorSources)
									.textStyle(.body1HighImportance)
									.foregroundColor(.app.gray2)
									.padding(.vertical, .medium1)
							} else {
								Image(asset: AssetResource.iconHardwareFactorSource)
									.frame(.medium)
									.padding(.vertical, .medium2)

								Text(viewStore.navigationTitle)
									.textStyle(.sheetTitle)
									.foregroundColor(.app.gray1)
									.padding(.bottom, .medium1)
							}

							if viewStore.showHeaders {
								if let subtitle = viewStore.subtitle {
									Text(subtitle)
										.foregroundColor(.app.gray1)
										.textStyle(.secondaryHeader)
										.padding(.horizontal, .medium1)
										.padding(.bottom, .medium1)
								}

								//        FIXME: Uncomment and implement
								//        Button(L10n.FactorSourcesOfKindList.ledgerFactorSourceInfoCaption) {
								//                viewStore.send(.whatIsAFactorSourceButtonTapped)
								//        }
								//        .buttonStyle(.info)
								//        .flushedLeft
							}
						}
						.multilineTextAlignment(.center)

						ledgerList(viewStore: viewStore)
							.padding(.bottom, .medium1)

						Button(L10n.FactorSourcesOfKindList.addNewFactorSource) {
							viewStore.send(.addNewFactorSourceButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: false))

						Spacer(minLength: 0)
					}
				}
				.frame(
					minWidth: 0,
					maxWidth: .infinity
				)
				.footer(visible: viewStore.allowSelection) {
					WithControlRequirements(
						viewStore.selectedFactorSourceControlRequirements,
						forAction: { viewStore.send(.confirmedFactorSource($0.selectedFactorSource)) }
					) { action in
						Button(L10n.FactorSourcesOfKindList.continueWithFactorSource, action: action)
							.buttonStyle(.primaryRectangular)
							.padding(.bottom, .medium1)
					}
				}
				.onFirstTask { @MainActor in
					await viewStore.send(.onFirstTask).finish()
				}
			}
			.destinations(with: store)
		}

		@ViewBuilder
		private func ledgerList(viewStore: ViewStoreOf<FactorSourcesOfKindList>) -> some SwiftUI.View {
			switch viewStore.factorSources {
			case .idle, .loading, .failure,
			     // We are already showing `subtitleNoFactorSources` in the header
			     .success([]) where viewStore.showHeaders:
				EmptyView()
			case .success([]):
				Text(L10n.FactorSourcesOfKindList.subtitleNoFactorSources)
					.foregroundColor(.app.gray1)
					.textStyle(.secondaryHeader)
					.multilineTextAlignment(.center)

			case let .success(factorSources):
				VStack(spacing: .medium1) {
					if viewStore.allowSelection {
						Selection(
							viewStore.binding(
								get: \.ledgersArray,
								send: { .selectedFactorSource(id: $0?.first?.id) }
							),
							from: factorSources,
							requiring: .exactly(1)
						) { item in
							FactorSourceRowView(
								viewState: .init(factorSource: item.value),
								isSelected: item.isSelected,
								action: item.action
							)
						}
					} else {
						ForEach(factorSources) { factorSource in
							FactorSourceRowView(viewState: .init(factorSource: factorSource))
						}
					}
				}
			}
		}
	}
}

extension View {
	@MainActor
	fileprivate func destinations(with store: StoreOf<FactorSourcesOfKindList>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
		return addNewFactorSourceSheet(with: destinationStore)
			.addNewP2PLinkSheet(with: destinationStore)
			.noP2PLinkAlert(with: destinationStore)
	}

	@MainActor
	private func addNewFactorSourceSheet(with destinationStore: PresentationStoreOf<FactorSourcesOfKindList.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /FactorSourcesOfKindList.Destinations.State.addNewFactorSource,
			action: FactorSourcesOfKindList.Destinations.Action.addNewFactorSource,
			content: { AddFactorSourceFactorSource.View(store: $0) }
		)
	}

	@MainActor
	private func addNewP2PLinkSheet(with destinationStore: PresentationStoreOf<FactorSourcesOfKindList.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /FactorSourcesOfKindList.Destinations.State.addNewP2PLink,
			action: FactorSourcesOfKindList.Destinations.Action.addNewP2PLink,
			content: { NewConnection.View(store: $0) }
		)
	}

	@MainActor
	private func noP2PLinkAlert(with destinationStore: PresentationStoreOf<FactorSourcesOfKindList.Destinations>) -> some View {
		alert(
			store: destinationStore,
			state: /FactorSourcesOfKindList.Destinations.State.noP2PLink,
			action: FactorSourcesOfKindList.Destinations.Action.noP2PLink
		)
	}
}
