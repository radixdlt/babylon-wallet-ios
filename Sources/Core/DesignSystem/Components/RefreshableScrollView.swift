import SwiftUI

// MARK: - RefreshableScrollView
/// This view simulates pull-to-refresh support on ScrollView before iOS 16.
///
/// On iOS 16+ it uses ScrollView.
/// On iOS 15 it falls back to List with modifiers removing all its default rows styling.
@MainActor
public struct RefreshableScrollView<Content: View>: View {
	var showsIndicators: Bool
	var content: () -> Content

	public init(
		showsIndicators: Bool = true,
		@ViewBuilder content: @escaping () -> Content
	) {
		self.showsIndicators = showsIndicators
		self.content = content
	}

	public var body: some View {
		if #available(iOS 16, *) {
			ScrollView(
				showsIndicators: showsIndicators,
				content: content
			)
		} else {
			List {
				content()
					.frame(maxWidth: .infinity, alignment: .center)
					.listRowSeparatorTint(.clear)
					.listRowBackground(Color.clear)
					.listRowInsets(EdgeInsets())
			}
			.listStyle(.plain)
		}
	}
}

#if DEBUG
struct RefreshableScrollView_Previews: PreviewProvider {
	static var previews: some View {
		RefreshableScrollView {
			Text("Pull me down to refresh!").padding()
		}
		.refreshable {
			try? await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
			print("Refreshed")
		}
	}
}
#endif
