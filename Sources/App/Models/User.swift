import Fluent
import Vapor
import BindleShared

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

    @Field(key: .contactType)
    var contactType: ContactType

    @OptionalField(key: .password)
    var password: String?

    @OptionalField(key: .appleIdentifier)
    var appleIdentifier: String?

    @OptionalEnum(key: .emailVerified)
    var emailVerified: EmailVerificationType?

    @OptionalField(key: .imageURL)
    var imageURL: String?

    @Children(for: \Order.$user)
    var orders: [Order]

    @Children(for: \Trip.$user)
    var trips: [Trip]

    @Children(for: \Rating.$userTo)
    var ratings: [Rating]

    init() { }

    init(id: UUID? = nil, firstName: String?, lastName: String? = nil, email: String,
         contactType: ContactType, password: String? = nil, appleIdentifier: String? = nil,
         emailVerified: EmailVerificationType? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
        self.appleIdentifier = appleIdentifier
        self.emailVerified = emailVerified
        self.contactType = contactType
    }
}

extension FieldKey {
    static let firstName: FieldKey = "firstName"
    static let lastName: FieldKey = "lastName"
    static let email: FieldKey = "email"
    static let appleIdentifier: FieldKey = "appleIdentifier"
    static let emailVerified: FieldKey = "emailVerified"
    static let password: FieldKey = "password"
    static let imageURL: FieldKey = "imageURL"
}
