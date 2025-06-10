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
							Section {
								VStack {
									ForEach(0 ..< 5) { _ in
										Card {
											HStack {
												Image(asset: AssetResource.stakes)

												Spacer()
												Image(asset: AssetResource.iconLinkOut)
													.foregroundColor(.secondaryText)
											}
											.padding()
										}
									}
								}
							} header: {
								HStack {
									Text("Socials").textStyle(.body1Header)

									Spacer()
									Text("See More").textStyle(.body2Link)
										.foregroundStyle(.textButton)
								}
							}

							Section {
								VStack {
									ForEach(InfoLinkSheet.GlossaryItem.allCases) { _ in
										Card {}
									}
								}
							} header: {
								HStack {
									Text("Learn")
										.textStyle(.body1Header)
									Spacer()
									Text("See More").textStyle(.body2Link)
										.foregroundStyle(.textButton)
								}
							}

							Section {
								VStack {
									ForEach(0 ..< 5) { idx in
										Card {
											PlainListRow(title: "\(idx)") {
												EmptyView()
											}
										}
									}
								}
							} header: {
								HStack {
									Text("Announcements").textStyle(.body1Header)
									Spacer()
									Text("See More").textStyle(.body2Link)
										.foregroundStyle(.textButton)
								}
							}
						}
						.padding()
					}
					.background(.secondaryBackground)
				}
			}
		}
	}
}
