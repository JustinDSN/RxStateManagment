import UIKit
import RxCocoa
import RxSwift

class RootViewController: UIViewController {
  
  //MARK: Properties
  
  private let disposeBag = DisposeBag()
  
  @IBOutlet weak var createAccountButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    createAccountButton.rx.tap.subscribe(onNext: { _ in
      let createAccountViewController = CreateAccountViewController()
      self.present(createAccountViewController, animated: true, completion: nil)
    }).disposed(by: disposeBag)
  }
  
}
