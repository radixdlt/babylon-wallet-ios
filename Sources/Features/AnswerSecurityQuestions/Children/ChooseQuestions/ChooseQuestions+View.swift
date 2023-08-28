import FeaturePrelude

// MARK: - ChooseQuestions.View
extension ChooseQuestions {
	public struct ViewState: Equatable {
		let availableQuestions: [SecurityQuestion]
		let selectionRequirement: SelectionRequirement
		var selectedQuestions: [SecurityQuestion]?
		var securityQuestionsToUse: NonEmpty<OrderedSet<SecurityQuestion>>?
		let minimumNumberOfQuestions: Int
		let minimumNumberCorrectAnswers: Int
		init(state: ChooseQuestions.State) {
			let selectionRequirement = state.selectionRequirement

			self.availableQuestions = state.availableQuestions.elements
			self.selectionRequirement = selectionRequirement
			self.selectedQuestions = state.selectedQuestions
			self.minimumNumberOfQuestions = state.keyDerivationScheme.minimumNumberOfQuestions
			self.minimumNumberCorrectAnswers = state.keyDerivationScheme.minimumNumberCorrectAnswers

			self.securityQuestionsToUse = {
				guard let selected = selectedQuestions else { return nil }
				return NonEmpty(rawValue: .init(uncheckedUniqueElements: selected))
			}()
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
					VStack(spacing: .small1) {
						// FIXME: Strings
						Text("Choose at least #\(viewStore.minimumNumberOfQuestions) security questions. You will only need to remember #\(viewStore.minimumNumberCorrectAnswers)")
							.font(.app.body1Header)
						Selection(
							selection,
							from: viewStore.availableQuestions,
							requiring: viewStore.selectionRequirement
						) { item in
							ChooseyQuestionRowView(item: item)
						}
					}
					.padding()
				}
				.navigationTitle("Choose Questions") // FIXME: Strings
				.footer {
					WithControlRequirements(
						viewStore.securityQuestionsToUse,
						forAction: { viewStore.send(.confirmedSelectedQuestions($0)) }
					) { action in
						// FIXME:
						Button("Answer chosen questions", action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
			}
		}
	}
}

// MARK: - ChooseyQuestionRowView
@MainActor
struct ChooseyQuestionRowView: SwiftUI.View {
	let question: SecurityQuestion
	let isSelected: Bool
	let action: () -> Void
	init(item: SelectionItem<SecurityQuestion>) {
		self.question = item.value
		self.isSelected = item.isSelected
		self.action = item.action
	}

	var body: some SwiftUI.View {
		Button(action: action) {
			HStack {
				Text("\(question.question.rawValue)?")
					.font(.app.body1HighImportance)
					.foregroundColor(.app.white)

				Spacer()

				CheckmarkView(
					appearance: .light,
					isChecked: isSelected
				)
			}
			.padding(.medium1)
			.background(
				Color.black
					.brightness(isSelected ? -0.1 : 0)
			)
			.cornerRadius(.small1)
		}
		.buttonStyle(.inert)
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
