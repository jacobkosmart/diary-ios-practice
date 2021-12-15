//
//  DiaryDetailViewController.swift
//  04_Diary
//
//  Created by Jacob Ko on 2021/12/15.
//

import UIKit

protocol DiaryDetailViewDelegate: AnyObject {
	func didSelecteDelete(indexPath: IndexPath)
}

class DiaryDetailViewController: UIViewController {
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var contenctsTextView: UITextView!
	@IBOutlet weak var dateLabel: UILabel!
	weak var delegate: DiaryDetailViewDelegate?
	
	// diary list 화면에서 전달 받을 property
	var diary: Diary?
	var indexPath: IndexPath?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.configureView()
	}
	
	// property 를 통해 전달받은 diary 객체를 view 에 초기화 시키기
	private func configureView() {
		guard let diary = self.diary else { return }
		self.titleLabel.text = diary.title
		self.contenctsTextView.text = diary.contents
		self.dateLabel.text = self.dateToString(date: diary.date)
	}
	
	// Date type 을 String 으로 바꾸는 method
	private func dateToString(date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "yy년 MM월 dd일(EEEEE)"
		formatter.locale = Locale(identifier: "ko_KR")
		return formatter.string(from: date)
	}
	
	//addObserver selector
	@objc func editDiaryNofitication(_ notification: Notification) {
		guard let diary = notification.object as? Diary else { return }
		guard let row = notification.userInfo?["indexPath.row"] as? Int else { return }
		self.diary = diary
		self.configureView()
	}
	
	// editBtn 을 누르면 그에 맞는 indexPath 에 따라서 값을 writeDiaryViewController 에 전달함
	@IBAction func tapEditBtn(_ sender: UIButton) {
		guard let viewController = self.storyboard?.instantiateViewController(identifier: "WriteDiaryViewController" ) as? WriteDiaryViewController else { return }
		guard let indexPath = self.indexPath else { return }
		guard let diary = self.diary else { return }
		viewController.diaryEditorMode = .edit(indexPath, diary)
		
		// Notification Observer 을 추가하게 되면 특정 이름의 notification 의 event 가 있었는지 계속 관찰하게 되고, 특정 event 가 발생할때 작업을 수행하게 됩니다
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(editDiaryNofitication(_:)),
			name: NSNotification.Name("editDiary"),
			object: nil
		)
		
		self.navigationController?.pushViewController(viewController, animated: true)
	}
	
	// deleteBtn 을 누르면 indexPath 에 맞게 delegate 에 didSelecteDelete 가 실행되게 함
	@IBAction func tabDeleteBtn(_ sender: UIButton) {
		guard let indexPath = self.indexPath else { return }
		self.delegate?.didSelecteDelete(indexPath: indexPath)
		self.navigationController?.popViewController(animated: true)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}
