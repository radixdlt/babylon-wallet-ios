// MARK: - LocalAuthenticationConfig
struct LocalAuthenticationConfig: Equatable, Sendable, CustomStringConvertible {
	let isPasscodeSetUp: Bool

	// Optional since user or app might have cancelled query after passcode query finished
	let isBiometricsSetUp: Bool?

	private init(
		isPasscodeSetUp: Bool,
		isBiometricsSetUp: Bool?
	) {
		if !isPasscodeSetUp, isBiometricsSetUp == true {
			fatalError("Not possible")
		}

		self.isPasscodeSetUp = isPasscodeSetUp
		self.isBiometricsSetUp = isBiometricsSetUp
	}
}

extension LocalAuthenticationConfig {
	static let biometricsAndPasscodeSetUp = Self(
		isPasscodeSetUp: true,
		isBiometricsSetUp: true
	)

	static let neitherBiometricsNorPasscodeSetUp = Self(
		isPasscodeSetUp: false,
		isBiometricsSetUp: false // irrelevant
	)

	static let passcodeSetUpButNotBiometrics = Self(
		isPasscodeSetUp: true,
		isBiometricsSetUp: false
	)

	static let passcodeSetUpButBiometricsIsUnknown = Self(
		isPasscodeSetUp: true,
		isBiometricsSetUp: nil
	)
}

extension LocalAuthenticationConfig {
	var description: String {
		switch (isPasscodeSetUp, isBiometricsSetUp) {
		case (true, .some(true)):
			"Biometrics (and passcode)"
		case (true, .some(false)):
			"Passcode only (no bio)"
		case (true, .none):
			"Passcode is setup, unknown if biometrics is set up"
		case (false, _):
			"Neither bio nor passcode"
		}
	}
}
