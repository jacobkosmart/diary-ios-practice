//
//  DiaryDetailViewController.swift
//  04_Diary
//
//  Created by Jacob Ko on 2021/12/15.
//

import UIKit

// NotificationCenter로 하기 때문에 delegate 이 없어도 됨
// protocol DiaryDetailViewDelegate: AnyObject {
// 	func didSelecteDelete(indexPath: IndexPath)
//
// 	func didSelectHeart(indexPath: IndexPath, isHeart: Bool)
// }

class DiaryDetailViewController: UIViewController {
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var contenctsTextView: UITextView!
	@IBOutlet weak var dateLabel: UILabel!
	// weak var delegate: DiaryDetailViewDelegate?
	var heartBtn: UIBarButtonItem?
	
	// diary list 화면에서 전달 받을 property
	var diary: Diary?
	var indexPath: IndexPath?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.configureView()
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(heartDiaryNotification(_:)),
			name: NSNotification.Name("heartDiary"),
			object: nil
		)
	}
	
	// property 를 통해 전달받은 diary 객체를 view 에 나타내기
	private func configureView() {
		guard let diary = self.diary else { return }
		self.titleLabel.text = diary.title
		self.contenctsTextView.text = diary.contents
		self.dateLabel.text = self.dateToString(date: diary.date)
		self.heartBtn = UIBarButtonItem(image: nil, style: .plain, target: self, action: #selector(tabHeartBtn))
		self.heartBtn?.image = diary.isHeart ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart")
		self.heartBtn?.tintColor = .red
		self.navigationItem.rightBarButtonItem = self.heartBtn
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
		self.diary = diary
		self.configureView()
	}
	
	// 두페이지의 즐겨찾기 sync 가 맞게 하는 selector
	@objc func heartDiaryNotification(_ notification: Notification) {
		guard let heartDiary = notification.object as? [String: Any] else { return }
		guard let isHeart = heartDiary["isHeart"] as? Bool else { return }
		guard let uuidString = heartDiary["uuidString"] as? String else { return }
		guard let diary = self.diary else { return }
		if diary.uuidString == uuidString {
			self.diary?.isHeart = isHeart
			self.configureView()
		}
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
		// indexPath 대신 uuid 값을 불러오기
		// guard let indexPath = self.indexPath else { return }
		guard let uuidString = self.diary?.uuidString else { return }
		// delegate 더이상 필요 없음 (NotificationCenter 로 대체)
		// self.delegate?.didSelecteDelete(indexPath: indexPath)
		NotificationCenter.default.post(
			name: NSNotification.Name("deleteDiary"),
			object: uuidString, // indexPath uuidString 이 전달되게 함
			userInfo: nil)
		self.navigationController?.popViewController(animated: true)
	}
	
	// tabheartBtn action selector
	@objc func tabHeartBtn() {
		// 즐겨찾기 토글 기능 (on / off 기능)
		guard let isHeart = self.diary?.isHeart else { return }
		// 즐겨찾기 에서도 더이상 indexPath 대신 uuidString 사용
		// guard let indexPath = self.indexPath else { return }
		
		if isHeart {
			self.heartBtn?.image = UIImage(systemName: "heart")
		} else {
			self.heartBtn?.image = UIImage(systemName: "heart.fill")
		}
		self.diary?.isHeart = !isHeart
		// delegate 으로 보낼경우 1:1 밖에 보낼 수 없기 때문에 NotificationCenter 을 이용해서 값을 보내야지 favorite 에서도 볼 수 있게 됨
		// self.delegate?.didSelectHeart(indexPath: indexPath, isHeart: self.diary?.isHeart ?? false)
		// Notification 에 isHeart 여부 보내기 logic
		NotificationCenter.default.post(
			name: NSNotification.Name("heartDiary"),
			object: [
				"diary" : self.diary,
				"isHeart" : self.diary?.isHeart ?? false,
				"uuidString": diary?.uuidString
			],
			userInfo: nil
		)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}
