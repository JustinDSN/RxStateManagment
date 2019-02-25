import Foundation
import RxSwift

class UserService {
  enum CreateUserError: Error {
    case invalidPassword
  }
  
  static let UserServiceScheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
  
  func createUser(email: String, password: String) -> Observable<User> {
    if password.count < 3 {
      return Observable.error(CreateUserError.invalidPassword)
    } else {
      return Observable.just(User(email: email, password: password)).delay(5.0, scheduler: UserService.UserServiceScheduler)
    }
  }
  
  func checkEmail(email: String) -> Observable<Bool> {
    return Observable.just(true)
  }
}
