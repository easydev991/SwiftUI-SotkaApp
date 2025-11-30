import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct MainUserFormTests {
    @Test
    func isNotReadyToRegister_empty() {
        let form = emptyForm
        #expect(!form.isReadyToRegister)
    }

    @Test
    func isNotReadyToRegister_userName() {
        let form = makeForm(userName: "")
        #expect(!form.isReadyToRegister)
    }

    @Test
    func isNotReadyToRegister_email() {
        let form = makeForm(email: "")
        #expect(!form.isReadyToRegister)
    }

    @Test
    func isNotReadyToRegister_passwordCount() {
        let form = makeForm(password: "short")
        #expect(!form.isReadyToRegister)
    }

    @Test
    func isNotReadyToRegister_gender() {
        let form = makeForm(gender: .unspecified)
        #expect(!form.isReadyToRegister)
    }

    @Test
    func isNotReadyToRegister_age() {
        let form = makeForm(birthDate: .now)
        #expect(!form.isReadyToRegister)
    }

    @Test
    func isReadyToRegister() {
        let form = makeForm()
        #expect(form.isReadyToRegister)
    }

    @Test
    func isNotReadyToSave_empty() {
        let oldForm = makeForm()
        let newForm = emptyForm
        #expect(!newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func isNotReadyToSave_equal() {
        let oldForm = makeForm()
        let newForm = makeForm()
        #expect(!newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func isNotReadyToSave_userName() {
        let oldForm = makeForm()
        let newForm = makeForm(userName: "")
        #expect(!newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func isNotReadyToSave_email() {
        let oldForm = makeForm()
        let newForm = makeForm(email: "")
        #expect(!newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func isNotReadyToSave_fullName() {
        let oldForm = makeForm()
        let newForm = makeForm(fullName: "")
        #expect(!newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func isNotReadyToSave_gender() {
        let oldForm = makeForm()
        let newForm = makeForm(gender: .unspecified)
        #expect(!newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func isNotReadyToSave_age() {
        let oldForm = makeForm()
        let newForm = makeForm(birthDate: .now)
        #expect(!newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func isReadyToSave_userName() {
        let oldForm = makeForm(userName: "old")
        let newForm = makeForm()
        #expect(newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func isReadyToSave_fullName() {
        let oldForm = makeForm(fullName: "old")
        let newForm = makeForm()
        #expect(newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func isReadyToSave_email() {
        let oldForm = makeForm(email: "old@old.com")
        let newForm = makeForm()
        #expect(newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func isReadyToSave_password() {
        let oldForm = makeForm(password: "oldPassword")
        let newForm = makeForm()
        #expect(newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func isReadyToSave_birthDate() throws {
        let oldDate = try #require(Calendar.current.date(from: .init(year: 1980, month: 1, day: 1)))
        let oldForm = makeForm(birthDate: oldDate)
        let newForm = makeForm()
        #expect(newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func isReadyToSave_country() {
        let oldForm = makeForm(country: .init(cities: [], id: "0", name: "0"))
        let newForm = makeForm()
        #expect(newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func isReadyToSave_city() {
        let oldForm = makeForm(city: .init(id: "0", name: "", lat: nil, lon: nil))
        let newForm = makeForm()
        #expect(newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func isReadyToSave_gender() {
        let oldForm = makeForm(gender: .female)
        let newForm = makeForm()
        #expect(newForm.isReadyToSave(comparedTo: oldForm))
    }

    @Test
    func shouldUpdateOnAppear() {
        let form1 = makeForm(country: .init(cities: [], id: "1", name: ""), city: .init(id: "1", name: "", lat: nil, lon: nil))
        let form2 = makeForm(country: .init(cities: [], id: "1", name: "name"), city: .init(id: "1", name: "", lat: "", lon: ""))
        let form3 = makeForm(country: .init(cities: [], id: "1", name: ""), city: .init(id: "1", name: "name", lat: "", lon: ""))
        let form4 = makeForm(country: .init(cities: [], id: "1", name: "name"), city: .init(id: "1", name: "name", lat: "", lon: ""))
        [form1, form2, form3].forEach {
            #expect($0.shouldUpdateOnAppear)
        }
        #expect(!form4.shouldUpdateOnAppear)
    }

    // MARK: - requestParameters Tests

    @Test
    func requestParameters_allKeysPresent() {
        let form = makeForm()
        let params = form.requestParameters

        #expect(params.keys.contains("name"))
        #expect(params.keys.contains("fullname"))
        #expect(params.keys.contains("email"))
        #expect(params.keys.contains("gender"))
        #expect(params.keys.contains("country_id"))
        #expect(params.keys.contains("city_id"))
        #expect(params.keys.contains("birth_date"))
        #expect(params.keys.count == 7)
    }

    @Test
    func requestParameters_correctValues() {
        let form = makeForm(
            userName: "testUser",
            fullName: "Test Full Name",
            email: "test@example.com",
            country: .init(cities: [], id: "17", name: "Россия"),
            city: .init(id: "1", name: "Москва", lat: "55.75", lon: "37.62"),
            gender: .male
        )
        let params = form.requestParameters

        #expect(params["name"] == "testUser")
        #expect(params["fullname"] == "Test Full Name")
        #expect(params["email"] == "test@example.com")
        #expect(params["gender"] == "\(Gender.male.code)")
        #expect(params["country_id"] == "17")
        #expect(params["city_id"] == "1")
    }

    @Test
    func requestParameters_birthDateIsoFormat() {
        let form = makeForm()
        let params = form.requestParameters

        // Проверяем, что birth_date в ISO формате
        #expect(params["birth_date"] != nil)
        // Проверяем формат ISO: должна быть строка с датой
        if let birthDateString = params["birth_date"] {
            // Формат должен содержать T и Z или часовой пояс
            #expect(birthDateString.contains("T"))
        }
    }

    @Test
    func requestParameters_genderConversionToString() {
        let formMale = makeForm(gender: .male)
        let formFemale = makeForm(gender: .female)
        let formUnspecified = makeForm(gender: .unspecified)

        #expect(formMale.requestParameters["gender"] == "\(Gender.male.code)")
        #expect(formFemale.requestParameters["gender"] == "\(Gender.female.code)")
        #expect(formUnspecified.requestParameters["gender"] == "\(Gender.unspecified.code)")
    }

    @Test
    func requestParameters_countryAndCityIds() {
        let form = makeForm(
            country: .init(cities: [], id: "42", name: "США"),
            city: .init(id: "100", name: "Нью-Йорк", lat: "40.71", lon: "-74.01")
        )
        let params = form.requestParameters

        #expect(params["country_id"] == "42")
        #expect(params["city_id"] == "100")
    }

    @Test
    func requestParameters_differentFieldValues() {
        let form = makeForm(
            userName: "anotherUser",
            fullName: "Another Name",
            email: "another@test.com"
        )
        let params = form.requestParameters

        #expect(params["name"] == "anotherUser")
        #expect(params["fullname"] == "Another Name")
        #expect(params["email"] == "another@test.com")
    }
}

private extension MainUserFormTests {
    var emptyForm: MainUserForm { .init(.emptyValue) }

    func makeForm(
        userName: String = "userName",
        fullName: String = "Full name",
        email: String = "email@email.com",
        password: String = "goodPassword123",
        birthDate: Date = Constants.minUserAge,
        country: CountryResponse = .defaultCountry,
        city: CityResponse = .defaultCity,
        gender: Gender = .male
    ) -> MainUserForm {
        .init(
            userName: userName,
            fullName: fullName,
            email: email,
            password: password,
            birthDate: birthDate,
            gender: gender.code,
            country: country,
            city: city
        )
    }
}

extension User {
    static var emptyValue: User {
        .init(id: 0)
    }
}

extension MainUserForm {
    static var emptyValue: Self {
        .init(
            userName: "",
            fullName: "",
            email: "",
            password: "",
            birthDate: .now,
            gender: Gender.unspecified.code,
            country: .defaultCountry,
            city: .defaultCity
        )
    }
}
