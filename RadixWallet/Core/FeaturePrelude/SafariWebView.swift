import SafariServices
import SwiftUI

struct SafariWebView: UIViewControllerRepresentable {
	let url: URL

	func makeUIViewController(context: Context) -> SFSafariViewController {
		let sf = SFSafariViewController(url: url)
		sf.modalPresentationStyle = .overFullScreen
		sf.configuration.barCollapsingEnabled = true
		return sf
	}

	func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
