import UIKit

// MARK: - ContactSupportClient + DependencyKey
extension ContactSupportClient: DependencyKey {
	static var liveValue: ContactSupportClient {
		@Dependency(\.openURL) var openURL
		@Dependency(\.device) var device
		@Dependency(\.bundleInfo) var bundleInfo

		let recipient = ""
		let subject = "Customer Support Case"

		@Sendable
		func buildBody(additionalInfo: String?) async -> String {
			let version = bundleInfo.shortVersion
			let model = await device.localizedModel
			let systemVersion = await device.systemVersion

			return "\n\nApp version: \(version)\nDevice: \(model)\nSystem version: \(systemVersion)\n\(additionalInfo ?? "")"
		}

		return .init(
			openEmail: { additionalBodyInfo in
				guard !recipient.isEmpty else {
					return
				}

				let uiApplicaition = await UIApplication.shared
				let body = await buildBody(additionalInfo: additionalBodyInfo)

				for app in EmailApp.allCases {
					if let url = app.build(recipient: recipient, subject: subject, body: body), await uiApplicaition.canOpenURL(url) {
						return await openURL(url)
					}
				}
			},
			openSupport: {
				guard let url = URL(string: "https://t.me/radix_dlt") else {
					return
				}
				await openURL(url)
			},
			isEmailSupportAvailable: { !recipient.isEmpty }
		)
	}
}

// MARK: - ContactSupportClient.EmailApp
private extension ContactSupportClient {
	enum EmailApp: CaseIterable {
		case gmail
		case outlook
		case appleMail

		func build(recipient: String, subject: String, body: String) -> URL? {
			switch self {
			case .gmail:
				guard var components = URLComponents(string: "googlegmail://co") else {
					return nil
				}
				components.queryItems = [
					.init(name: "to", value: recipient),
					.init(name: "subject", value: subject),
					.init(name: "body", value: body),
				]
				return components.url

			case .outlook:
				guard var components = URLComponents(string: "ms-outlook://emails/new") else {
					return nil
				}
				components.queryItems = [
					.init(name: "to", value: recipient),
					.init(name: "subject", value: subject),
					.init(name: "body", value: body),
				]
				return components.url

			case .appleMail:
				guard var components = URLComponents(string: "mailto:\(recipient)") else {
					return nil
				}
				components.queryItems = [
					.init(name: "subject", value: subject),
					.init(name: "body", value: body),
				]
				return components.url
			}
		}
	}
}
