import Foundation

extension URLRequest {
	mutating func setHttpHeaderFields() {
		allHTTPHeaderFields = [
			"accept": "application/json",
			"Content-Type": "application/json",
			"RDX-Client-Name": "iOS Wallet",
			"RDX-Client-Version": rdxClientVersion ?? "UNKNOWN",
		]
	}

	private var rdxClientVersion: String? {
		guard
			let mainBundleInfoDictionary = Bundle.main.infoDictionary,
			let version = mainBundleInfoDictionary["CFBundleShortVersionString"] as? String,
			let buildNumber = mainBundleInfoDictionary["CFBundleVersion"] as? String
		else {
			return nil
		}

		return version
			+ "#" + buildNumber
			+ "-" + (BuildConfiguration.current?.description ?? "UNKNOWN")
	}
}
