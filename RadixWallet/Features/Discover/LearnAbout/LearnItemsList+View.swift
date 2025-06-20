import SwiftUI

// MARK: - LearnItemsList.View
extension Discover.LearnItemsList {
	struct View: SwiftUI.View {
		let store: StoreOf<Discover.LearnItemsList>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .small1) {
					ForEach(store.displayedItems) { item in
						Card(action: {
							store.send(.view(.learnItemTapped(item)))
						}) {
							PlainListRow(
								title: item.title,
								subtitle: item.description,
								accessory: nil,
							) {
								Image(source: item.icon.map(ImageSource.imageResource) ?? ImageSource.sytemImage("info.circle"))
									.resizable()
									.scaledToFill()
									.frame(.small)
							}
						}
					}
				}
				.frame(maxWidth: .infinity)
			}
		}
	}
}
