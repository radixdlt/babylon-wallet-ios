extension SensitiveInfoClient: DependencyKey {
	static var liveValue: SensitiveInfoClient {
		.init(
			read: { key in
				guard let filePath = Bundle.main.path(forResource: "SensitiveInfo", ofType: "plist") else {
					fatalError("Couldn't find file 'SensitiveInfo.plist'")
				}
				let plist = NSDictionary(contentsOfFile: filePath)
				guard let value = plist?.object(forKey: key.rawValue) as? String else {
					fatalError("Couldn't find value for key '\(key.rawValue)' in 'SensitiveInfo.plist'.")
				}
				if value.starts(with: "placeholder") {
					assertionFailure("Please set up your sensitive info tokens in 'SensitiveInfo.plist'")
				}
				return value
			}
		)
	}
}
