import FeaturePrelude
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
		let factorSources: Loadable<IdentifiedArrayOf<SavedOrDraftFactorSource<FactorSourceOfKind>>>
		let selectedFactorSourceID: FactorSourceID?
		let selectedFactorSource: SavedOrDraftFactorSource<FactorSourceOfKind>?
		let mode: State.Mode

		init(state: FactorSourcesOfKindList.State) {
			allowSelection = state.allowSelection
			showHeaders = state.showHeaders
			factorSources = state.$factorSources
			selectedFactorSourceID = state.selectedFactorSourceID
			mode = state.mode

			if let id = state.selectedFactorSourceID, let selectedFactorSource = state.factorSources?[id: id] {
				self.selectedFactorSource = selectedFactorSource
			} else {
				self.selectedFactorSource = nil
			}
		}

		var factorsArray: [SavedOrDraftFactorSource<FactorSourceOfKind>]? { .init(factorSources.wrappedValue ?? []) }

		var navigationTitle: String {
			if allowSelection {
				// FIXME: Strings
				return "Select Factor"
			} else {
				// FIXME: Strings
				return "Factors"
			}
		}

		var subtitle: String? {
			switch factorSources {
			case .idle, .loading:
				return nil
			case .failure:
				// FIXME: Strings
				return "Failed to load factors"
			case .success([]):
				// FIXME: Strings
				return "No factors"
			case .success:
				if allowSelection {
					// FIXME: Strings
					return "Select factor"
				} else {
					// FIXME: Strings
					return "Factors"
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
							if viewStore.mode == .onlyPresentList {
								// FIXME: Strings
								Text("Factors")
									.textStyle(.body1HighImportance)
									.foregroundColor(.app.gray2)
									.padding(.vertical, .medium1)
							} else {
								// FIXME: Icon
								Image(systemName: "lock.square.stack.fill")
									.frame(.medium)
									.padding(.vertical, .medium2)

								Text(viewStore.navigationTitle)
									.textStyle(.sheetTitle)
									.foregroundColor(.app.gray1)
									.padding(.bottom, .medium1)
							}

							if viewStore.showHeaders, let subtitle = viewStore.subtitle {
								Text(subtitle)
									.foregroundColor(.app.gray1)
									.textStyle(.secondaryHeader)
									.padding(.horizontal, .medium1)
									.padding(.bottom, .medium1)
							}
						}
						.multilineTextAlignment(.center)

						factorList(viewStore: viewStore)
							.padding(.bottom, .medium1)

						// FIXME: Strings
						Button("Add new factor") {
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
						viewStore.selectedFactorSource,
						forAction: { viewStore.send(.confirmedFactorSource($0)) }
					) { action in
						// FIXME: Strings
						Button("Continue", action: action)
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
		private func factorList(viewStore: ViewStoreOf<FactorSourcesOfKindList>) -> some SwiftUI.View {
			switch viewStore.factorSources {
			case .idle, .loading, .failure,
			     // We are already showing `subtitleNoFactorSources` in the header
			     .success([]) where viewStore.showHeaders:
				EmptyView()
			case .success([]):
				// FIXME: Strings
				Text("No factors")
					.foregroundColor(.app.gray1)
					.textStyle(.secondaryHeader)
					.multilineTextAlignment(.center)

			case let .success(factorSources):
				VStack(spacing: .medium1) {
					if viewStore.allowSelection {
						Selection(
							viewStore.binding(
								get: \.factorsArray,
								send: { .selectedFactorSource(id: $0?.first?.id) }
							),
							from: factorSources,
							requiring: .exactly(1)
						) { item in
							FactorSourceRowView(
								viewState: .init(factorSource: item.value.factorSource, describe: { $0.generalHint }),
								isSelected: item.isSelected,
								action: item.action
							)
						}
					} else {
						ForEach(factorSources) { factorSource in
							FactorSourceRowView(viewState: .init(factorSource: factorSource.factorSource, describe: { $0.generalHint }))
						}
					}
				}
			}
		}
	}
}

extension FactorSource {
	var generalHint: String {
		switch self {
		case let .device(factor): return factor.hint.name
		case let .ledger(factor): return factor.hint.name
		case let .offDeviceMnemonic(factor): return factor.hint.label.rawValue
		case let .trustedContact(factor): return factor.contact.name.rawValue
		case let .securityQuestions(factor): return "'\(factor.sealedMnemonic.securityQuestions.first.question.rawValue)' +\(factor.sealedMnemonic.securityQuestions.count - 1) more questions."
		}
	}
}

extension View {
	@MainActor
	fileprivate func destinations<F>(with store: StoreOf<FactorSourcesOfKindList<F>>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
		return addNewFactorSourceSheet(with: destinationStore)
	}

	@MainActor
	private func addNewFactorSourceSheet<F>(with destinationStore: PresentationStoreOf<FactorSourcesOfKindList<F>.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /FactorSourcesOfKindList.Destinations.State.addNewFactorSource,
			action: FactorSourcesOfKindList.Destinations.Action.addNewFactorSource,
			content: { F.FeatureForAddingNew.View(store: $0) }
		)
	}
}

// MARK: - FactorSourceRowView
@MainActor
public struct FactorSourceRowView: View {
	public struct ViewState: Equatable {
		let description: String
		let addedOn: Date
		let lastUsedOn: Date

		public init(factorSource: FactorSource, describe: (FactorSource) -> String) {
			self.description = describe(factorSource)
			self.addedOn = factorSource.addedOn
			self.lastUsedOn = factorSource.lastUsedOn
		}
	}

	private let viewState: ViewState
	private let isSelected: Bool?
	private let action: (() -> Void)?

	/// Creates a tappable card. If `isSelected` is non-nil, the card will have a radio button.
	public init(viewState: ViewState, isSelected: Bool? = nil, action: @escaping () -> Void) {
		self.viewState = viewState
		self.isSelected = isSelected
		self.action = action
	}

	/// Creates an inert card, with no selection indication.
	public init(viewState: ViewState) {
		self.viewState = viewState
		self.isSelected = nil
		self.action = nil
	}

	public var body: some View {
		Card(.app.gray5, action: action) {
			HStack(spacing: 0) {
				VStack(alignment: .leading, spacing: 0) {
					Text(viewState.description)
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)
						.padding(.bottom, .small1)

					LabelledDate(label: "Last used", date: viewState.lastUsedOn)
						.padding(.bottom, .small3)

					LabelledDate(label: "Added on", date: viewState.addedOn)
				}

				Spacer(minLength: 0)

				if let isSelected {
					RadioButton(
						appearance: .light,
						state: isSelected ? .selected : .unselected
					)
				}
			}
			.foregroundColor(.app.gray1)
			.padding(.horizontal, .large3)
			.padding(.vertical, .medium1)
		}
	}
}
