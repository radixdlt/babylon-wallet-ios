import ComposableArchitecture
import SwiftUI
extension FactorSourcesOfKindList.State {
	var viewState: FactorSourcesOfKindList.ViewState {
		.init(state: self)
	}
}

public extension FactorSourcesOfKindList {
	struct ViewState: Equatable {
		let allowSelection: Bool
		let factorSources: IdentifiedArrayOf<FactorSourceOfKind>
		let selectedFactorSourceID: FactorSourceID?
		let selectedFactorSource: FactorSourceOfKind?
		let mode: State.Mode
		let kind: FactorSourceKind
		let canAddNew: Bool

		init(state: FactorSourcesOfKindList.State) {
			self.allowSelection = state.mode == .selection
			self.factorSources = state.factorSources
			self.selectedFactorSourceID = state.selectedFactorSourceID?.embed()
			self.mode = state.mode

			if let id = state.selectedFactorSourceID, let selectedFactorSource = state.factorSources[id: id] {
				self.selectedFactorSource = selectedFactorSource
			} else {
				self.selectedFactorSource = nil
			}
			self.kind = state.kind
			self.canAddNew = state.canAddNew
		}

		var factorsArray: [FactorSourceOfKind]? { factorSources.elements }

		var navigationTitle: String {
			let title = kind.display
			guard allowSelection else {
				return title
			}
			return "Select \(title)"
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
									.resizable()
									.frame(.medium)
									.padding(.vertical, .medium2)

								Text(viewStore.navigationTitle)
									.textStyle(.sheetTitle)
									.foregroundColor(.app.gray1)
									.padding(.bottom, .medium1)
							}
						}
						.multilineTextAlignment(.center)

						factorList(viewStore: viewStore)
							.padding(.bottom, .medium1)

						if viewStore.canAddNew {
							// FIXME: Strings
							Button("Add new \(viewStore.kind.display)") {
								viewStore.send(.addNewFactorSourceButtonTapped)
							}
							.buttonStyle(.secondaryRectangular(shouldExpand: false))
						}

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
			.confirmationDialog(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /FactorSourcesOfKindList.Destinations.State.existingFactorSourceWillBeDeletedConfirmationDialog,
				action: FactorSourcesOfKindList.Destinations.Action.existingFactorSourceWillBeDeletedConfirmationDialog
			)
		}

		@ViewBuilder
		private func factorList(viewStore: ViewStoreOf<FactorSourcesOfKindList>) -> some SwiftUI.View {
			VStack(spacing: .medium1) {
				if viewStore.allowSelection {
					Selection(
						viewStore.binding(
							get: \.factorsArray,
							send: { .selectedFactorSource(id: $0?.first?.id) }
						),
						from: viewStore.factorSources,
						requiring: .exactly(1)
					) { item in
						FactorSourceRowView(
							viewState: .init(factorSource: item.value.embed(), describe: { $0.generalHint }),
							isSelected: item.isSelected,
							action: item.action
						)
					}
				} else {
					ForEach(viewStore.factorSources) { factorSource in
						FactorSourceRowView(viewState: .init(
							factorSource: factorSource.embed(),
							describe: { $0.generalHint }
						)
						)
					}
				}
			}
		}
	}
}

extension FactorSource {
	var generalHint: String {
		switch self {
		case let .device(factor): .init(factor.hint.name)
		case let .ledger(factor): .init(factor.hint.name)
		case let .offDeviceMnemonic(factor): .init(factor.hint.label.rawValue)
		case let .trustedContact(factor): .init(factor.contact.name.rawValue)
		case let .securityQuestions(factor): .init(stringLiteral: "*`\"\(factor.sealedMnemonic.securityQuestions.first.question.rawValue)?\"`* **+\(factor.sealedMnemonic.securityQuestions.count - 1) more questions**.")
		}
	}
}

extension View {
	@MainActor
	fileprivate func destinations(with store: StoreOf<FactorSourcesOfKindList<some BaseFactorSourceProtocol>>) -> some SwiftUI.View {
		let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
		return addNewFactorSourceSheet(with: destinationStore)
	}

	@MainActor
	private func addNewFactorSourceSheet<F>(with destinationStore: PresentationStoreOf<FactorSourcesOfKindList<F>.Destinations>) -> some SwiftUI.View where F: BaseFactorSourceProtocol {
		sheet(
			store: destinationStore,
			state: /FactorSourcesOfKindList.Destinations.State.addNewFactorSource,
			action: FactorSourcesOfKindList.Destinations.Action.addNewFactorSource,
			content: { ManageSomeFactorSource<F>.View(store: $0) }
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
		let isFlaggedForDeletion: Bool
		let kind: FactorSourceKind

		public init(
			factorSource: FactorSource,
			describe: (FactorSource) -> String
		) {
			self.kind = factorSource.kind
			self.description = describe(factorSource)
			self.addedOn = factorSource.addedOn
			self.lastUsedOn = factorSource.lastUsedOn
			self.isFlaggedForDeletion = factorSource.isFlaggedForDeletion
		}
	}

	private let viewState: ViewState
	private let isSelected: Bool?
	private let action: (() -> Void)?

	/// Creates a tappable card. If `isSelected` is non-nil, the card will have a radio button.
	public init(
		viewState: ViewState,
		isSelected: Bool? = nil,
		action: @escaping () -> Void
	) {
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
					Text("`\(viewState.kind.rawValue)`")

					Text(viewState.description)
						.foregroundColor(.app.gray1)
						.padding(.bottom, .small1)

					LabelledDate(label: "Last used", date: viewState.lastUsedOn)
						.padding(.bottom, .small3)

					LabelledDate(label: "Added on", date: viewState.addedOn)

					if viewState.isFlaggedForDeletion {
						Text("Deleted")
							.foregroundColor(.app.red1)
					}
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
		.disabled(viewState.isFlaggedForDeletion)
	}
}
