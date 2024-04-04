extension SensitiveInfoClient: DependencyKey {
	static var liveValue: SensitiveInfoClient {
		.init(
			read: { key in
				guard let filePath = Bundle.main.path(forResource: "SensitiveInfo", ofType: "plist") else {
					assertionFailure("Couldn't find file 'SensitiveInfo.plist'")
					return nil
				}
				let plist = NSDictionary(contentsOfFile: filePath)
				guard let value = plist?.object(forKey: key.rawValue) as? String else {
					assertionFailure("Couldn't find value for key '\(key.rawValue)' in 'SensitiveInfo.plist'.")
					return nil
				}
				if value.starts(with: "placeholder") {
					loggerGlobal.warning("Please set up your sensitive info tokens in 'SensitiveInfo.plist'")
				}
				return value
			}
		)
	}
}
