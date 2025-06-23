import SafariServices

// MARK: - BlogPostCard
struct BlogPostCard: View {
	let post: BlogPost
	let imageSizingBehavior: LoadableImageSize?
	let dropShadow: Bool

	var body: some View {
		Button(action: {
			let vc = SFSafariViewController(url: post.url)
			UIApplication.shared.firstKeyWindow?.rootViewController?.present(vc, animated: true)
		}) {
			VStack(alignment: .leading, spacing: .zero) {
				LoadableImage(url: post.image, size: imageSizingBehavior, placeholders: .shimmer)
				HStack {
					Text(post.name)
						.multilineTextAlignment(.leading)
						.lineSpacing(0)
						.lineLimit(3)
						.foregroundStyle(.primaryText)
						.textStyle(.body1Header)

					Spacer()

					Image(.iconLinkOut)
				}
				.padding(.horizontal, .medium3)
				.padding(.vertical, .small2)
				.frame(height: 80)
			}
		}
		.background(.primaryBackground)
		.clipShape(RoundedRectangle(cornerRadius: .medium3))
		.shadow(color: dropShadow ? .shadow.opacity(0.26) : .clear, radius: .medium3, x: .zero, y: .small2)
	}
}

private extension UIApplication {
	var firstKeyWindow: UIWindow? {
		UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.filter { $0.activationState == .foregroundActive }
			.first?.keyWindow
	}
}
