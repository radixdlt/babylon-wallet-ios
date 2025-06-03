import SwiftUI

extension InteractionReview {
	typealias ValidatorsState = ValidatorsView.ViewState
	typealias ValidatorState = ValidatorView.ViewState

	struct ValidatorsView: SwiftUI.View {
		let heading: InteractionReview.HeadingView
		let viewState: ViewState
		let action: () -> Void

		var body: some SwiftUI.View {
			VStack(alignment: .leading, spacing: .small2) {
				InteractionReview.ExpandableHeadingView(heading: heading, isExpanded: viewState.isExpanded, action: action)

				if viewState.isExpanded {
					VStack(spacing: .small2) {
						ForEach(viewState.validators) { validator in
							ValidatorView(viewState: validator)
						}
					}
					.transition(.opacity.combined(with: .scale(scale: 0.95)))
				}
			}
		}

		struct ViewState: Hashable, Sendable {
			let validators: [ValidatorView.ViewState]
			var isExpanded: Bool

			init(validators: [ValidatorView.ViewState], isExpanded: Bool = true) {
				self.validators = validators
				self.isExpanded = isExpanded
			}
		}
	}

	struct ValidatorView: SwiftUI.View {
		let viewState: ViewState

		struct ViewState: Hashable, Sendable, Identifiable {
			var id: ValidatorAddress { address }
			let address: ValidatorAddress
			let name: String?
			let thumbnail: URL?
		}

		var body: some SwiftUI.View {
			Card {
				HStack(spacing: .zero) {
					Thumbnail(.validator, url: viewState.thumbnail)
						.padding(.trailing, .medium3)

					VStack(alignment: .leading, spacing: .zero) {
						if let name = viewState.name {
							Text(name)
								.lineSpacing(-6)
								.lineLimit(1)
								.textStyle(.secondaryHeader)
								.foregroundColor(.primaryText)
						}

						AddressView(.address(.validator(viewState.address)))
					}

					Spacer(minLength: 0)
				}
				.frame(minHeight: .plainListRowMinHeight)
				.padding(.horizontal, .medium3)
				.contentShape(Rectangle())
			}
		}
	}
}
