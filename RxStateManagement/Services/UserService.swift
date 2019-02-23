import Foundation
import RxSwift

class UserService {
  // 6. Create error to demonstrate error handling
  enum CreateUserError: Error {
    case invalidPassword
  }
  
  static let UserServiceScheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
  
  func createUser(email: String, password: String) -> Observable<User> {
    // 7. Raise error
    if password.count < 3 {
      return Observable.error(CreateUserError.invalidPassword)
    } else {
      return Observable.just(User(email: email, password: password)).delay(5.0, scheduler: UserService.UserServiceScheduler)
    }
  }
}
