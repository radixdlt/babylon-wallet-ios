import FeaturePrelude

// MARK: - ChooseQuestions.View
extension ChooseQuestions {
	public struct ViewState: Equatable {
		let availableQuestions: [SecurityQuestion]
		let selectionRequirement: SelectionRequirement
		let selectedQuestions: [SecurityQuestion]?
		let securityQuestionsToUse: NonEmpty<OrderedSet<SecurityQuestion>>?

		init(state: ChooseQuestions.State) {
			let selectionRequirement = state.selectionRequirement

			self.availableQuestions = state.availableQuestions.elements
			self.selectionRequirement = selectionRequirement
			self.selectedQuestions = state.selectedQuestions
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ChooseQuestions>

		public init(store: StoreOf<ChooseQuestions>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: ChooseQuestions.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				let selection = viewStore.binding(
					get: \.selectedQuestions,
					send: { .selectedQuestionsChanged($0) }
				)
				ScrollView {
					VStack(spacing: .medium2) {
						VStack(spacing: .small1) {
							Selection(
								selection,
								from: viewStore.availableQuestions,
								requiring: viewStore.selectionRequirement
							) { item in
								Text("Question: \(String(describing: item.value))")
							}
						}

//						Button("Confirm question selection") {
//							viewStore.send(.mockChoseQuetions)
//						}.buttonStyle(.primaryRectangular)
					}
				}
				.footer {
					WithControlRequirements(
						{
							guard let selected = selection.wrappedValue else { return nil }
							return NonEmpty<OrderedSet>.init(rawValue: .init(uncheckedUniqueElements: selected))
						}(),
						forAction: { viewStore.send(.confirmedSelectedQuestions($0)) }
					) { action in
						Button(L10n.DAppRequest.ChooseAccounts.continue, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ChooseQuestions_Preview
struct ChooseQuestions_Preview: PreviewProvider {
	static var previews: some View {
		ChooseQuestions.View(
			store: .init(
				initialState: .previewValue,
				reducer: ChooseQuestions()
			)
		)
	}
}

extension ChooseQuestions.State {
	public static let previewValue = Self()
}
#endif
