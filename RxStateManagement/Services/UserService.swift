import Foundation
import RxSwift

class UserService {
  static let UserServiceScheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
  
  func createUser(email: String, password: String) -> Observable<User> {
    return Observable.just(User(email: email, password: password)).delay(5.0, scheduler: UserService.UserServiceScheduler)
  }
}
