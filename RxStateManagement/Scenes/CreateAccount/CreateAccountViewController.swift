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
    
    let submitEvent = createAccountButton.rx.tap
      .map({
        SubmitEvent(
          email: self.emailTextField.text!,
          password: self.passwordTextField.text!
        ) as SubmitUIEvent
      })
    
    let checkEmailEvent = emailTextField.rx.text
      .unwrap()
      .map({
        CheckEmailEvent(email: $0) as SubmitUIEvent
      })
    
    let events = Observable<SubmitUIEvent>.merge(submitEvent, checkEmailEvent)
    
    let submit = events
      .apply(submitUIEventTransformer)
      .apply(submitActionTransformer)
    
    let checkEmail = events
      .apply(checkEmailUIEventTransformer)
      .apply(checkEmailActionTransformer)
    
    
    
    
    
    
    //2. Blah
    //    let results = Observable.of(
    //      Result.checkEmailInFlight,
    //      Result.checkEmailInFlight,
    //      Result.submitEventInFlight,
    //      Result.submitEventSuccess
    //    )
    
    // 3. Use scan to manage state
    //    let uiModels = results.scan(UIModel.idle) { (initialState, result) -> UIModel in
    //      switch (result) {
    //      case .checkEmailInFlight, .submitEventInFlight:
    //        return .inProgress
    //      case .checkEmailSuccess:
    //        return .idle
    //      case .submitEventSuccess:
    //        return .success
    //      }
    //    }
    
    // 4. Decouple UIEvents and UIModels, by using Actions and mapping to Results
    
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
  
  func submitUIEventTransformer(_ events: Observable<UIEvent>) -> Observable<SubmitAction> {
    return events.filter({ $0.isSubmitEvent })
      .map({ event in
        switch event {
        case .submitEvent(email: let email, password: let password):
          return SubmitAction(email: email, password: password)
        default:
          fatalError("Only `.submitEvent` should be handled by this observable sequence.")
        }
      })
  }
  
  func checkEmailUIEventTransformer(_ events: Observable<UIEvent>) -> Observable<CheckEmailAction> {
    return events.filter({ $0.isCheckEmailEvent})
      .map({ event in
        switch event {
        case .checkEmailEvent(email: let email):
          return CheckEmailAction(email: email)
        default:
          fatalError("Only `.checkEmailEvent` should be handled by this observable sequence.")
        }
      })
  }
  
  func submitActionTransformer(_ actions: Observable<SubmitAction>) -> Observable<SubmitResult> {
    return actions.flatMap({ (action) -> Observable<SubmitResult> in
      return self.userService.createUser(email: action.email,
                                         password: action.password)
        .map({ _ in SubmitResult.success })
        .catchError({ error in Observable.just(SubmitResult.error(message: error.localizedDescription))})
        .observeOn(MainScheduler.instance)
        .startWith(SubmitResult.inProgress)
    })
  }
  
  func checkEmailActionTransformer(_ actions: Observable<CheckEmailAction>) -> Observable<CheckEmailResult> {
    return actions
      .delay(0.2, scheduler: MainScheduler.instance)
      .flatMapLatest({ (action) -> Observable<CheckEmailResult> in
        return self.userService.checkEmail(email: action.email)
          .map({ _ in CheckEmailResult.success })
          .catchError({ error in Observable.just(CheckEmailResult.error(message: error.localizedDescription))})
          .observeOn(MainScheduler.instance)
          .startWith(CheckEmailResult.inProgress)
      })
  }
  
}

