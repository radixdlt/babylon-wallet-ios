import Resources

#if os(iOS)
import UIKit
#endif

@MainActor
public func configureWalletAppUIAppearance() {
	#if os(iOS)
	UINavigationBar.appearance().largeTitleTextAttributes = [
		.font: FontConvertible.Font.app.sheetTitle,
	]
	UINavigationBar.appearance().titleTextAttributes = [
		.font: FontConvertible.Font.app.secondaryHeader,
	]
	#endif
}
