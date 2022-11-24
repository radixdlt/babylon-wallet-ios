import SwiftUI

#if os(iOS)
@_implementationOnly import SwiftUIPullToRefresh

extension RefreshAction: @unchecked Sendable {}
#endif

// MARK: - RefreshableScrollView
@MainActor
public struct RefreshableScrollView<Content: View>: View {
	@Environment(\.refresh) var refresh

	var showsIndicators: Bool
	var content: Content

	public init(
		showsIndicators: Bool = true,
		@ViewBuilder content: () -> Content
	) {
		self.showsIndicators = showsIndicators
		self.content = content()
	}

	public var body: some View {
		if #available(iOS 16, macOS 13, *) {
			ScrollView(showsIndicators: showsIndicators, content: { content })
		} else {
			#if os(iOS)
			SwiftUIPullToRefresh.RefreshableScrollView(
				showsIndicators: showsIndicators,
				onRefresh: { done in
					Task { @MainActor in
						await refresh?()
						done()
					}
				},
				content: { content }
			)
			#else
			ScrollView(showsIndicators: showsIndicators, content: { content })
			#endif
		}
	}
}

#if DEBUG
struct RefreshableScrollView_Previews: PreviewProvider {
	static var previews: some View {
		RefreshableScrollView {
			Text("Content").padding()
		}
		.background(Color.blue)
		.refreshable {
			try? await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
			print("Refreshed")
		}
	}
}
#endif
