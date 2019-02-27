import UIKit
import RxCocoa
import RxSwift
import RxSwiftExt

// UIEvents
protocol SubmitUIEvent {}

struct CheckEmailEvent: SubmitUIEvent {
  let email: String
}

struct SubmitEvent: SubmitUIEvent {
  let email: String
  let password: String
}

// UIModels
enum UIModel: Equatable {
  case idle
  case inProgress
  case success
  case error(message: String)
}

// Actions

protocol Action {}

struct SubmitAction: Action {
  let email: String
  let password: String
}

struct CheckEmailAction: Action {
  let email: String
}

// Results

protocol Result {}

enum SubmitResult: Result {
  case inProgress
  case success
  case error(message: String)
}

enum CheckEmailResult: Result {
  case inProgress
  case success
  case error(message: String)
}

class CreateAccountViewController: UIViewController {
  
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
    
    let submitEvent: Observable<SubmitUIEvent> = createAccountButton.rx.tap
      .map({
        SubmitEvent(
          email: self.emailTextField.text!,
          password: self.passwordTextField.text!
        )
      })
    
    let checkEmailEvent: Observable<SubmitUIEvent> = emailTextField.rx.text
      .unwrap()
      .filter({ !$0.isEmpty })
      .map({
        CheckEmailEvent(email: $0)
      })
    
    //1. Merge all `SubmitUIEvent` into a single sequence
    let uiEvents = Observable<SubmitUIEvent>.merge(submitEvent, checkEmailEvent)
    
    //2. Transform `SubmitUIEvent`s into UI agnostic actions
    let actions = uiEvents.apply(uiEventTransformer)

    //3. Transform `Actions` into `Results`
    let results = actions.apply(actionTransformer)
    
    //4. Calculate the `UIModel` from the resulting sequence of `Results` (this is where the state management happens)
    let uiModels = results.scan(UIModel.idle) { (initialState, result) -> UIModel in
      switch result {
      case let submitResult as SubmitResult:
        switch submitResult {
        case .inProgress:
          return .inProgress
        case .success:
          return .success
        case .error(message: let message):
          return .error(message: message)
        }
      case let checkEmailResult as CheckEmailResult:
        switch checkEmailResult {
        case .inProgress:
          return .inProgress
        case .success:
          return .idle
        case .error(message: let message):
          return .error(message: message)
        }
      default:
        fatalError("Unexpected result.")
      }
    }
    
    //5. Using the calculated state, bind it to the UI
    uiModels
      .subscribe(onNext: { (model) in
        switch model {
        case .idle:
          print("Idle")
          self.createAccountButton.isEnabled = true
          self.processingView.isHidden = true
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
  
  func uiEventTransformer(_ events: Observable<SubmitUIEvent>) -> Observable<Action> {
    return events.multicast({ return PublishSubject<SubmitUIEvent>() }, selector: { (shared) -> Observable<Action> in
        return Observable.merge(
          shared.ofType(SubmitEvent.self).apply(self.submitUIEventTransformer),
          shared.ofType(CheckEmailEvent.self).apply(self.checkEmailUIEventTransformer)
        )
    })
  }
  
  func submitUIEventTransformer(_ events: Observable<SubmitEvent>) -> Observable<Action> {
    return events
      .map({ event in
        return SubmitAction(email: event.email, password: event.password)
      })
  }
  
  func checkEmailUIEventTransformer(_ events: Observable<CheckEmailEvent>) -> Observable<Action> {
    return events
      .map({ event in
        return CheckEmailAction(email: event.email)
      })
  }
  
  func actionTransformer(_ actions: Observable<Action>) -> Observable<Result> {
    return actions.multicast({ return PublishSubject<Action>() }, selector: { (shared) -> Observable<Result> in
      return Observable.merge(
        shared.ofType(SubmitAction.self).apply(self.submitActionTransformer),
        shared.ofType(CheckEmailAction.self).apply(self.checkEmailActionTransformer)
      )
    })
  }
  
  func submitActionTransformer(_ actions: Observable<SubmitAction>) -> Observable<Result> {
    return actions.flatMap({ (action) -> Observable<Result> in
      return self.userService.createUser(email: action.email,
                                         password: action.password)
        .map({ _ in SubmitResult.success })
        .catchError({ error in Observable.just(SubmitResult.error(message: error.localizedDescription))})
        .observeOn(MainScheduler.instance)
        .startWith(SubmitResult.inProgress)
    })
  }
  
  func checkEmailActionTransformer(_ actions: Observable<CheckEmailAction>) -> Observable<Result> {
    return actions
      .delay(0.2, scheduler: MainScheduler.instance)
      .flatMapLatest({ (action) -> Observable<Result> in
        return self.userService.checkEmail(email: action.email)
          .map({ _ in CheckEmailResult.success })
          .catchError({ error in Observable.just(CheckEmailResult.error(message: error.localizedDescription))})
          .observeOn(MainScheduler.instance)
          .startWith(CheckEmailResult.inProgress)
      })
  }
}
