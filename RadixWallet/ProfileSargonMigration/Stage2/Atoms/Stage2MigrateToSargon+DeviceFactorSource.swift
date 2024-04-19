import Foundation
import Sargon

extension DeviceFactorSource {
	func removingMainFlag() -> Self {
		var copy = self
		copy.common.flags.removeAll(where: { $0 == .main })
		return copy
	}
}

extension DeviceFactorSource {
	/// **B**abylon **D**evice **F**actor **S**ource
	public var isExplicitMainBDFS: Bool {
		isBDFS && isExplicitMain
	}

	/// **B**abylon **D**evice **F**actor **S**ource
	public var isBDFS: Bool {
		guard supportsBabylon else { return false }
		if hint.mnemonicWordCount == .twentyFour {
			return true
		} else {
			loggerGlobal.error("BDFS with non 24 words mnemonic found, probably this profile originated from Android? Which with 'BDFS Error' with 1.0.0 allowed usage of 12 word Olympia Mnemonic.")
			return false
		}
	}
}

extension FactorSourceProtocol {
	public var isExplicitMain: Bool {
		common.flags.contains(.main)
	}
}
