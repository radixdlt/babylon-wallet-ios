import SwiftUI

// MARK: - AccountBannerView
struct AccountBannerView: View {
	let kind: Kind

	var body: some View {
		HStack(spacing: .zero) {
			image
				.resizable()
				.scaledToFit()
				.frame(width: .medium3, height: .medium3)

			Text(text)
				.textStyle(.body2HighImportance)
				.padding(.leading, .small2)
				.multilineTextAlignment(.leading)

			Spacer()
		}
		.foregroundColor(.white)
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

		case let .accessControllerTimedRecovery(state):
			switch state {
			case .inProgress:
				Image(systemName: "hourglass")
			case .unknown:
				Image(.error)
			}
		}
	}

	private var text: String {
		switch kind {
		case let .securityProblem(message):
			message
		case let .lockerClaim(dappName):
			L10n.HomePage.accountLockerClaim(dappName ?? L10n.DAppRequest.Metadata.unknownName)
		case let .accessControllerTimedRecovery(state):
			switch state {
			case let .inProgress(countdown):
				if let countdown {
					L10n.HandleAccessControllerTimedRecovery.Banner.recoveryInProgress(countdown)
				} else {
					L10n.HandleAccessControllerTimedRecovery.Banner.readyToConfirm
				}
			case .unknown:
				L10n.HandleAccessControllerTimedRecovery.Banner.unknownRecovery
			}
		}
	}
}

// MARK: AccountBannerView.Kind
extension AccountBannerView {
	enum Kind: Sendable, Hashable {
		case securityProblem(message: String)
		case lockerClaim(dappName: String?)
		case accessControllerTimedRecovery(state: TimedRecoveryBannerState)
	}

	enum TimedRecoveryBannerState: Sendable, Hashable {
		/// Recovery is in progress and the countdown (if any) is provided
		case inProgress(countdown: String?)
		/// Recovery is unknown to the wallet
		case unknown
	}
}
