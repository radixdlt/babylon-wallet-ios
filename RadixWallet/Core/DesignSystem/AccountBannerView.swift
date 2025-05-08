import SwiftUI

// MARK: - AccountBannerView
struct AccountBannerView: View {
	let kind: Kind

	var body: some View {
		HStack(spacing: .zero) {
			image
				.resizable()
				.frame(width: .medium3, height: .medium3)

			Text(text)
				.textStyle(.body2HighImportance)
				.padding(.leading, .small2)
				.multilineTextAlignment(.leading)

			Spacer()
		}
		.foregroundColor(.app.white)
		.padding(.small1)
		.background(.backgroundTransparent)
		.cornerRadius(.small2)
	}

	private var image: Image {
		switch kind {
		case .securityProblem:
			Image(.error)

		case .lockerClaim:
			Image(systemName: "bell")
		}
	}

	private var text: String {
		switch kind {
		case let .securityProblem(message):
			message
		case let .lockerClaim(dappName):
			L10n.HomePage.accountLockerClaim(dappName ?? L10n.DAppRequest.Metadata.unknownName)
		}
	}
}

// MARK: AccountBannerView.Kind
extension AccountBannerView {
	enum Kind: Sendable, Hashable {
		case securityProblem(message: String)
		case lockerClaim(dappName: String?)
	}
}
