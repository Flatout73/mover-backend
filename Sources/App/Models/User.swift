import Fluent
import Vapor

enum EmailVerificationType: String, Codable {
    case google
    case apple
}

final class User: Model, Content, Authenticatable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?

    @OptionalField(key: .firstName)
    var firstName: String?

    @OptionalField(key: .lastName)
    var lastName: String?

    @Field(key: .email)
    var email: String

    @OptionalField(key: .phone)
    var phone: String?

    @OptionalField(key: .password)
    var password: String?

    @OptionalField(key: .appleIdentifier)
    var appleIdentifier: String?

    @OptionalField(key: .emailVerified)
    var emailVerified: EmailVerificationType?

    @Children(for: \Order.$user)
    var orders: [Order]

    @Children(for: \Trip.$user)
    var trips: [Trip]

    init() { }

    init(id: UUID? = nil, firstName: String, lastName: String? = nil, email: String,
         phone: String? = nil, password: String? = nil, appleIdentifier: String? = nil,
         emailVerified: EmailVerificationType? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.password = password
        self.appleIdentifier = appleIdentifier
        self.emailVerified = emailVerified
    }
}

extension FieldKey {
    static let firstName: FieldKey = "firstName"
    static let lastName: FieldKey = "lastName"
    static let email: FieldKey = "email"
    static let phone: FieldKey = "phone"
    static let appleIdentifier: FieldKey = "appleIdentifier"
    static let emailVerified: FieldKey = "emailVerified"
    static let password: FieldKey = "password"
}
