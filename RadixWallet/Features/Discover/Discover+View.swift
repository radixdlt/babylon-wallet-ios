import SwiftUI

// MARK: - Discover.View
extension Discover {
	struct View: SwiftUI.View {
		let store: StoreOf<Discover>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .zero) {
					Text("Discover")
						.foregroundColor(Color.primaryText)
						.background(.primaryBackground)
						.textStyle(.body1Header)
						.padding(.vertical, .small1)
					Separator()
					ScrollView {
						VStack(spacing: .medium1) {
							socialsSection
							learnSection
						}
						.padding()
					}
					.background(.secondaryBackground)
				}
				.destinations(store: store)
			}
		}
	}
}

extension Discover.View {
	@ViewBuilder
	var socialsSection: some SwiftUI.View {
		Section {
			VStack(spacing: .small1) {
				ForEach(store.socialLinks) { link in
					Card(action: {
						store.send(.view(.socialLinkTapped(link)))
					}) {
						PlainListRow(title: link.description, accessory: .iconLinkOut, icon: {
							Image(link.platform.icon)
								.resizable()
								.scaledToFit()
								.frame(.small)
						})
					}
				}
			}
		} header: {
			HStack {
				Text("Socials").textStyle(.body1Header)
				Spacer()
			}
		}
	}

	@ViewBuilder
	var learnSection: some SwiftUI.View {
		Section {
			VStack(spacing: .small1) {
				ForEach(store.learnItems.prefix(3)) { item in
					Card(action: {
						store.send(.view(.learnItemTapped(item)))
					}) {
						PlainListRow(
							title: item.title,
							subtitle: item.description,
							accessory: nil,
						) {
							Image(item.icon)
								.resizable()
								.scaledToFit()
								.frame(.small)
						}
					}
				}
			}
		} header: {
			HStack {
				Text("Learn about").textStyle(.body1Header)
				Spacer()
				Button("See More") {
					store.send(.view(.seeMoreLearnItemsTapped))
				}
				.buttonStyle(.blueText)
			}
		}
	}
}

private extension View {
	func destinations(store: StoreOf<Discover>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: \.destination)

		return navigationDestination(store: destinationStore.scope(state: \.learnAbout, action: \.learnAbout)) {
			Discover.LearnAbout.View(store: $0)
		}
	}
}
