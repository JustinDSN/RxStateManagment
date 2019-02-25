import UIKit
import RxCocoa
import RxSwift
import RxSwiftExt

class CreateAccountViewController: UIViewController {
  // 1. Add checkEmailEvent, with helper properties for filtering.
  enum UIEvent {
    case submitEvent(email: String, password: String)
    case checkEmailEvent(email: String)
    
    var isSubmitEvent: Bool {
      if case .submitEvent = self {
        return true
      } else {
        return false
      }
    }
    
    var isCheckEmailEvent: Bool {
      if case .checkEmailEvent = self {
        return true
      } else {
        return false
      }
    }
  }
  
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
    
    // 2. Extract discrete UIEvents (submitEvent & checkEmailEvent)
    let submitEvent = createAccountButton.rx.tap
      .map({
        UIEvent.submitEvent(
          email: self.emailTextField.text!,
          password: self.passwordTextField.text!
        )
      })
    
    let checkEmailEvent = emailTextField.rx.text
      .unwrap()
      .map({
        UIEvent.checkEmailEvent(email: $0)
      })
    
    let events = Observable.merge(submitEvent, checkEmailEvent)
    
    // 3. Handle UIEvents discretely (submit, checkEmail)
    let submit = events
      .filter { $0.isSubmitEvent }
      .flatMap { (event) -> Observable<UIModel> in
        switch event {
        case .submitEvent(email: let email, password: let password):
          return self.userService.createUser(email: email,
                                             password: password)
            .map({ _ in UIModel.success })
            .catchError({ error in Observable.just(UIModel.error(message: error.localizedDescription))})
            .observeOn(MainScheduler.instance)
            .startWith(UIModel.inProgress)
        default:
          fatalError("Only `.submitEvent` should be handled by this observable sequence.")
        }
    }
    
    let checkEmail = events
      .filter { $0.isCheckEmailEvent }
      .delay(0.2, scheduler: MainScheduler.instance)
      .flatMapLatest { (event) -> Observable<UIModel> in
        switch event {
        case .checkEmailEvent(email: let email):
          //TODO: Handle UIModels Correctly
          return self.userService.checkEmail(email: email)
            .map({ _ in UIModel.success })
            .catchError({ error in Observable.just(UIModel.error(message: error.localizedDescription))})
            .observeOn(MainScheduler.instance)
            .startWith(UIModel.inProgress)
        default:
          fatalError("Only `.checkEmailEvent` should be handled by this observable sequence.")
        }
    }
    
    let models = Observable.merge(submit, checkEmail)
    
    // 4. Subscribe to UIModel observable
    models
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
  
  func showError(_ message: String) {
    let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    
    self.present(alertController, animated: true, completion: nil)
  }
  
}

