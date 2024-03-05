import ComposableArchitecture

// struct NPSSurvey: FeatureReducer {
//    struct State: Hashable, Sendable {
//        var recommendationScore: Int? = nil
//        var scoreReason: String? = nil
//    }
//
//    enum ViewAction: Equatable {
//        case recommendationScoreTapped(Int)
//        case scoreReasonTextChanged(String)
//    }
//
//    func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
//        switch viewAction {
//        case let .recommendationScoreTapped(score):
//            state.recommendationScore = score
//        case let .scoreReasonTextChanged(reason):
//            state.scoreReason = reason
//        }
//        return .none
//    }
// }
//
// extension NPSSurvey {
//    struct View: SwiftUI.View {
//        var body: some SwiftUI.View {
//            Text("Holla")
//        }
//    }
// }

import SwiftUI

// MARK: - FeedbackView
struct FeedbackView: View {
	@State private var feedbackScore: Int?
	@State private var feedbackText: String = ""

	var body: some View {
		NavigationView {
			VStack {
				Text("How’s it Going?")
					.textStyle(.sheetTitle)
					.foregroundStyle(.app.gray1)

				Text("How likely are you to recommend Radix and the Radix Wallet to your friends or colleagues?")
					.multilineTextAlignment(.center)
					.textStyle(.body1Regular)
					.foregroundStyle(.app.gray1)

				FlowLayout {
					ForEach(0 ..< 11) { score in
						Text("\(score)")
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray1)
							.frame(.small)
							.overlay(
								Circle()
									.stroke(.app.gray3, lineWidth: 1.0)
							)
					}
				}
				.padding()

				Text("What’s the main reason for your score?")
					.padding(.top)

				TextField("Let us know...", text: $feedbackText)
					.textFieldStyle(RoundedBorderTextFieldStyle())
					.padding()

				Button(action: {
					// Handle feedback submission
				}) {
					Text("Submit Feedback - Thanks!")
						.foregroundColor(.white)
						.padding()
						.frame(maxWidth: .infinity)
						.background(Color.blue)
						.cornerRadius(10)
				}
				.padding()

				Spacer()
			}
			.navigationBarItems(trailing: Button(action: {
				// Handle close action
			}) {
				Image(systemName: "xmark")
			})
			.padding()
		}
	}
}

// MARK: - FeedbackView_Previews
struct FeedbackView_Previews: PreviewProvider {
	static var previews: some View {
		FeedbackView()
	}
}
