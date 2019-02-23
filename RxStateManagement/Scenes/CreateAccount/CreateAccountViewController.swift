import UIKit
import RxCocoa
import RxSwift

class CreateAccountViewController: UIViewController {
  // 2. Create UIEvent
  enum UIEvent {
    case submitEvent(email: String, password: String)
  }
  
  // 3. Create UIModel
  enum UIModel: Equatable {
    case inProgress
    case success
    case error(message: String)
  }
  
  //MARK: Properties
  
  private let disposeBag = DisposeBag()
  private let userService = UserService()
  
  //MARK: Outlets
  
  @IBOutlet private weak var createAccountButton: UIButton!
  @IBOutlet private weak var emailTextField: UITextField!
  @IBOutlet private weak var passwordTextField: UITextField!
  @IBOutlet private weak var processingView: UIView!
  @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // 5. Manage state using UIEvent and UIModel
    createAccountButton
      .rx
      .tap
      .map({ UIEvent.submitEvent(email: self.emailTextField.text!,
                                 password: self.passwordTextField.text!)})
      .flatMap { (event) -> Observable<UIModel> in
        switch event {
        case .submitEvent(email: let email, password: let password):
            return self.userService.createUser(email: email,
                                               password: password)
              .map({ _ in UIModel.success })
              .catchError({ error in Observable.just(UIModel.error(message: error.localizedDescription))})
              .observeOn(MainScheduler.instance)
              .startWith(UIModel.inProgress)
        }
      }
      .subscribe(onNext: { (model) in
        switch model {
        case .inProgress:
          print("In Progress")
          self.createAccountButton.isEnabled = false
          self.processingView.isHidden = false
        case .success:
          print("Success")
          self.dismiss(animated: true, completion: nil)
        case .error(message: let message):
          print("Error")
          self.processingView.isHidden = true
          self.createAccountButton.isEnabled = true
          self.showError(message)
        }
      }, onError: { (error) in
        fatalError("Programmer error, all errors should be handled.")
      })
      .disposed(by: disposeBag)
  }
  
  // 4. Extract showError method
  func showError(_ message: String) {
    let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    
    self.present(alertController, animated: true, completion: nil)
  }
  
}

