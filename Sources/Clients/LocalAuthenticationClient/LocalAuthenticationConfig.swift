import Foundation

// MARK: - LocalAuthenticationConfig
public struct LocalAuthenticationConfig: Equatable, Sendable, CustomStringConvertible {
	public let isPasscodeSetUp: Bool

	// Optional since user or app might have cancelled query after passcode query finished
	public let isBiometricsSetUp: Bool?

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

public extension LocalAuthenticationConfig {
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

public extension LocalAuthenticationConfig {
	var description: String {
		switch (isPasscodeSetUp, isBiometricsSetUp) {
		case (true, .some(true)):
			return "Biometrics (and passcode)"
		case (true, .some(false)):
			return "Passcode only (no bio)"
		case (true, .none):
			return "Passcode is setup, unknown if biometrics is set up"
		case (false, _):
			return "Neither bio nor passcode"
		}
	}
}
