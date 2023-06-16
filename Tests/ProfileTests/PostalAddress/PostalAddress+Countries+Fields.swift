import Foundation

extension PersonaFieldValue.PostalAddress.Country {
	var fields: [[PersonaFieldValue.PostalAddress.Field.Discriminator]] {
		switch self {
		case .afghanistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]
		case .albania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .algeria:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .andorra:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .angola:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .argentina:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province],
				[.country],
			]
		case .armenia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .australia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.suburb],
				[.state, .postalCodeNumber],
				[.country],
			]

		case .austria:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .azerbaijan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .bangladesh:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .belarus:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province],
				[.country],
			]
		case .belgium:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .benin:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .bolivia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .bosniaAndHerzegovinia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .botswana:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .brazil:
			return [
				[.streetLine0],
				[.streetLine1],
				[.neighbourhood],
				[.city],
				[.state],
				[.postalCodeNumber],
				[.country],
			]

		case .bruneiDarussalam:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .bulgaria:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .burkinaFaso:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .burundi:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .cambodia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postcodeNumber],
				[.country],
			]

		case .cameroon:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]
		case .canada:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province, .postalCodeString],
				[.country],
			]

		case .capeVerde:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .centralAfricanRepublic:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .chad:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .chile:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .china:
			return [
				[.country],
				[.province],
				[.prefectureLevelCity],
				[.districtString],
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
			]

		case .colombia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.department],
				[.country],
			]

		case .comoros:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .croatia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .cyprus:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .czechRepublic:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .denmark:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .democraticRepublicOfTheCongo:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .djibouti:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .ecuador:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
				[.city],
				[.country],
			]

		case .egypt:
			return [
				[.streetLine0],
				[.streetLine1],
				[.districtString],
				[.governorate],
				[.country],
			]

		case .equatorialGuinea:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .eritrea:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .estonia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .eswatini:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCodeNumber],
				[.country],
			]

		case .ethiopia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .finland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .france:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .frenchGuiana:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .gabon:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .gambia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .georgia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .germany:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .ghana:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .greece:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .guinea:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .guineaBissau:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .guyana:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .hongKong:
			return [
				[.country],
				[.region, .districtString],
				[.streetLine0],
				[.streetLine1],
			]

		case .hungary:
			return [
				[.postalCodeNumber, .city],
				[.streetLine0],
				[.streetLine1],
				[.country],
			]

		case .iceland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .india:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postcodeNumber],
				[.state],
				[.country],
			]

		case .iran:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .iraq:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCodeNumber],
				[.country],
			]

		case .ireland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.county, .postcodeNumber],
				[.country],
			]

		case .indonesia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province, .postalCodeNumber],
				[.country],
			]

		case .isreal:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province, .country],
			]

		case .italy:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province, .country],
			]

		case .ivoryCoast:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .japan:
			return [
				[.postalCodeNumber],
				[.prefecture, .county],
				[.furtherDivisionsLine0],
				[.furtherDivisionsLine1],
				[.country],
			]

		case .jordan:
			return [
				[.postalDistrict],
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .kazakhstan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.districtString],
				[.region],
				[.country],
				[.postalCodeNumber],
			]
		case .kenya:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCodeNumber],
				[.country],
			]

		case .kuwait:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province],
				[.country],
			]

		case .laos:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .latvia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .lebanon:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .lesotho:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .liberia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .libya:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .liechtenstein:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .lithuania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .luxembourg:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .macao:
			return [
				[.country],
				[.districtNumber, .city],
				[.streetLine0],
				[.streetLine1],
			]

		case .madagascar:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .malawi:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .malaysia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.state],
				[.country],
			]

		case .mali:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .malta:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCodeNumber],
				[.country],
			]

		case .mauritania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .mauritius:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
				[.city],
				[.country],
			]

		case .mexico:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.state],
				[.country],
			]

		case .moldova:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .monaco:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .mongolia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .montenegro:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .morocco:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .mozambique:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province],
				[.country],
			]

		case .myanmar:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .nepal:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .namibia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .netherlands:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .newZealand:
			return [
				[.streetLine0],
				[.streetLine1],
				[.suburb],
				[.city, .postcodeNumber],
				[.country],
			]

		case .niger:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .nigeria:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.state],
				[.country],
			]

		case .northKorea:
			return [
				[.country],
				[.province],
				[.city],
				[.streetLine0],
				[.streetLine1],
			]

		case .northMacedonia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .norway:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .oman:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
				[.city],
				[.province],
				[.country],
			]

		case .pakistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .palestinianTerritories:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .papuaNewGuinea:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.province],
				[.country],
			]

		case .paraguay:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .philippines:
			return [
				[.streetLine0],
				[.streetLine1],
				[.districtString, .postalCodeNumber],
				[.city, .country],
			]

		case .peru:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .poland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .qatar:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .republicOfCongo:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .romania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .russia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.subjectOfTheFederation],
				[.country],
				[.postalCodeNumber],
			]

		case .reunion:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .rwanda:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .sanMarino:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province],
				[.country],
			]

		case .senegal:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .saudiArabia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.districtString],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .serbia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .singapore:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .sierraLeone:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .slovakia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .slovenia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .somalia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.region, .postalCodeNumber],
				[.country],
			]

		case .southAfrica:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province],
				[.postalCodeNumber],
				[.country],
			]

		case .southKorea:
			return [
				[.country],
				[.province],
				[.city],
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
			]

		case .southSudan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
				[.city],
				[.country],
			]

		case .spain:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.province, .country],
			]

		case .sriLanka:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.postalCodeNumber],
				[.country],
			]

		case .sweden:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .switzerland:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .sudan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber],
				[.city],
				[.country],
			]

		case .suriname:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.districtString],
				[.country],
			]

		case .taiwan:
			return [
				[.country],
				[.zipNumber, .county],
				[.township],
				[.streetLine0],
				[.streetLine1],
			]

		case .tajikistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .tanzania:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .thailand:
			return [
				[.streetLine0],
				[.streetLine1],
				[.districtString],
				[.province, .postalCodeNumber],
				[.country],
			]

		case .togo:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]

		case .tunisia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .turkey:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .districtString],
				[.city, .country],
			]

		case .turkmenistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .uganda:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]
		case .ukraine:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.province],
				[.postalCodeNumber],
				[.country],
			]

		case .unitedStates:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.state, .zipNumber],
				[.country],
			]

		case .unitedArabEmirates:
			return [
				[.streetLine0],
				[.streetLine1],
				[.area],
				[.city],
				[.country],
			]

		case .unitedKingdom:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.county],
				[.postcodeString],
				[.country],
			]

		case .uruguay:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.department],
				[.country],
			]

		case .uzbekistan:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
				[.postalCodeNumber],
			]

		case .vaticanCity:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .venzuela:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city, .postalCodeNumber],
				[.state],
				[.country],
			]
		case .vietnam:
			return [
				[.streetLine0],
				[.streetLine1],
				[.province],
				[.city, .postalCodeNumber],
				[.country],
			]

		case .yemen:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]

		case .zambia:
			return [
				[.streetLine0],
				[.streetLine1],
				[.postalCodeNumber, .city],
				[.country],
			]
		case .zimbabwe:
			return [
				[.streetLine0],
				[.streetLine1],
				[.city],
				[.country],
			]
		}
	}
}
