import UIKit
import RxCocoa
import RxSwift

class CreateAccountViewController: UIViewController {
  
  //MARK: Properties
  
  private let disposeBag = DisposeBag()
  private let userService = UserService()
  
  //MARK: Outlets
  
  @IBOutlet private weak var createAccountButton: UIButton!
  @IBOutlet private weak var emailTextField: UITextField!
  @IBOutlet private weak var passwordTextField: UILabel!
  @IBOutlet private weak var processingView: UIView!
  @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    createAccountButton.rx.tap.do(onNext: { (_) in
      self.createAccountButton.isEnabled = false
      self.processingView.isHidden = false
    }).flatMap { (_) -> Observable<User> in
      return self.userService.createUser(email: self.emailTextField.text!, password: self.passwordTextField.text!)
      }
      .observeOn(MainScheduler.instance)
      .do(onNext: { (_) in
        self.processingView.isHidden = true
      })
      .subscribe(onNext: { (user) in
        print("Success")
        
        self.dismiss(animated: true, completion: nil)
      }, onError: { (error) in
        self.createAccountButton.isEnabled = true
        
        print("Error")
        
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
      })
      .disposed(by: disposeBag)

  }
  
}

